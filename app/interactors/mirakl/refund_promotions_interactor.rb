# frozen_string_literal: true

module Mirakl
    class RefundPromotionsInteractor < ApplicationInteractor
    def call
      return log_event(:info, 'skipping, positive refund remaining') unless refund_remaining.positive?
      unless promotion_amount.positive?
        return log_event(:info, 'skipping, positive promotion amount (refund amount)')
      end

      send_promotion_credit_email
    end

    private

    def order_line_reimbursement
      @order_line_reimbursement ||= context.order_line_reimbursement
    end

    def spree_order
      @spree_order ||= order_line_reimbursement.line_item.order
    end

    def reimbursement
      @reimbursement ||= order_line_reimbursement.reimbursement
    end

    def promotion_amount
      @promotion_amount = available_to_refund >= refund_remaining ? refund_remaining : available_to_refund
    end

    def available_to_refund
      original_order_total = spree_order.payments.valid.sum(:amount) - spree_order.promo_total
      original_order_total - refunded_total
    end

    def refund_remaining
      @refund_remaining ||= begin
        (order_line_reimbursement.line_item.price * order_line_reimbursement.quantity) - refunded_total
      end
    end

    def refunded_total
      @refunded_total ||= order_line_reimbursement.refunded_total
    end

    def send_promotion_credit_email
      spree_order.user ? issue_store_credit : generate_gift_card_reimbursement

      Mirakl::PromotionRefundMailer.promotion_refund_email(order_line_reimbursement,
                                                           promo_code: context.promotion_code&.value).deliver_later
    end

    def issue_store_credit
      credit = spree_order.user.store_credits.create!(
        amount: promotion_amount,
        category: Spree::StoreCreditCategory.find_or_create_by(name: 'Mirakl Promotion Refund'),
        created_by: Spree::User.mirakl_admin,
        memo: "Credit for Order ##{spree_order.number}",
        currency: spree_order.currency
      )

      Spree::Reimbursement::Credit.create!(creditable: credit, reimbursement: reimbursement, amount: promotion_amount)
      credit
    end

    def generate_gift_card_reimbursement
      result = Maisonette::GiftCardGeneratorOrganizer.call!(
        original_amount: promotion_amount,
        name: "Refund for order #{spree_order.number}"
      )

      context.promotion = result.promotion
      context.promotion_code = result.promotion_code

      Spree::Reimbursement::GiftCard.create!(
        spree_promotion_code_id: result.promotion_code.id,
        reimbursement: reimbursement,
        amount: promotion_amount
      )
    end
  end
end
