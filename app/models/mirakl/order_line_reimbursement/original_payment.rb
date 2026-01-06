# frozen_string_literal: true

module Mirakl
  class OrderLineReimbursement < Mirakl::Base
    module OriginalPayment
      private

      def calculate_amount_to_refund(payment, remaining_refund_amount)
        payment.credit_allowed >= remaining_refund_amount ? remaining_refund_amount : payment.credit_allowed
      end

      def payments
        line_item
          .order

          .payments
          .valid
          .sort_by { |payment| payment.store_credit? ? 1 : 0 } # refund store credit last
          .select { |payment| payment.credit_allowed.positive? }
      end

      def create_refund(payment, amount_to_refund)
        Spree::Refund.create!(
          payment: payment,
          amount: amount_to_refund,
          reason: refund_reason,
          reimbursement: reimbursement,
          perform_after_create: false
          # TODO: tax_voided: item_refund.tax_voided
        )
      end

      # Break the refund into pieces to match payments' amounts
      def perform_original_payment_refund
        remaining_refund_amount = total - refunded_total

        payments.each do |payment|
          next unless remaining_refund_amount.positive?

          amount_to_refund = calculate_amount_to_refund(payment, remaining_refund_amount)
          remaining_refund_amount -= amount_to_refund

          create_refund(payment, amount_to_refund).perform!
        end
      end
    end
  end
end
