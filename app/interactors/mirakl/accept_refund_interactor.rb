# frozen_string_literal: true

module Mirakl
  class AcceptRefundInteractor < ApplicationInteractor
    include Mirakl::Api

    def call
      return unless order_line_reimbursement.refund?

      put('/payment/refund', payload: accept_refund_payload)
    end

    private

    def accept_refund_payload
      { refunds: [{ amount: order_line_reimbursement.mirakl_total.to_f,
                    currency_iso_code: order_line_reimbursement.line_item.currency,
                    payment_status: 'OK',
                    refund_id: order_line_reimbursement.mirakl_reimbursement_id }] }.to_json
    end

    def order_line_reimbursement
      context.order_line_reimbursement
    end
  end
end
