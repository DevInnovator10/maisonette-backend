# frozen_string_literal: true

module OrderManagement
  class CreateRefundsInteractor < ApplicationInteractor
    helper_methods :refunds, :current_user, :order, :total
    required_params :refunds, :current_user, :order

    before :validate_context

    def call
      ActiveRecord::Base.transaction do
        process_refunds

        order.reload
        order.recalculate

        context.fail!(error: 'No Refund/Credit created') if no_refunds?
      end
    end

    private

    def validate_context
      context.fail!(error: 'Missing refunds') if refunds.nil?
      context.fail!(error: 'Missing current user') if current_user.nil?
      context.fail!(error: 'Missing order') if order.nil?
      context.fail!(error: 'Missing reimbursement and total') if context.reimbursement.nil? && total.nil?
    end

    def no_refunds?
      reimbursement.refunds.none? &&
        reimbursement.credits.none? &&
        Spree::Reimbursement::GiftCard.where(reimbursement: reimbursement).none?
    end

    def process_refunds
      refunds.each do |refund_info|
        result = RefundCredit::CreateOrganizer.call(
          refund_info.merge(
            reimbursement: reimbursement,
            refund_reason: refund_reason(refund_info),
            current_user: current_user
          )
        )

        context.fail!(error: result.error) if result.failure?
      end
    end

    def refund_reason(refund)
      context.refund_reason ||= Spree::RefundReason.find_by!(mirakl_code: refund[:reason_code]) ||
                                Spree::RefundReason.find_by!(name: 'Item returned')
    end

    def reimbursement
      context.reimbursement ||= Spree::Reimbursement.create!(
        reimbursement_status: 'reimbursed',
        total: total,
        order: order
      )
    end
  end
end
