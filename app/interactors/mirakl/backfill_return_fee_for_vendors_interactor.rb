# frozen_string_literal: true

module Mirakl
  class BackfillReturnFeeForVendorsInteractor < Mirakl::ProcessReimbursements::CreateReturnFeesInteractor
    helper_methods :mirakl_order

    def call
      fetch_order_line_reimbursements
      return if context.new_refund_order_line_reimbursements.blank?

      context.new_refund_order_line_reimbursements.each do |order_line_reimbursement|
        next unless eligible_for_return_fee?(order_line_reimbursement)

        charge_vendor_for_return_fee(order_line_reimbursement)
      end
    end

    private

    def fetch_order_line_reimbursements
      context.new_refund_order_line_reimbursements = mirakl_order.order_line_reimbursements.select do |reimbursement|
        reimbursement.order_line.return_fee.zero? && reimbursement.refund?
      end

    end
  end
end
