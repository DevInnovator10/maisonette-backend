# frozen_string_literal: true

module Mirakl
  class ReimbursementPreview < ActionMailer::Preview
    def rejection
      unless (order_line_reimbursement = Mirakl::OrderLineReimbursement.rejection.last)
        raise 'Your database needs at least Mirakl::OrderLineReimbursement rejection to render this preview'
      end

      Mirakl::RefundProcessingMailer.refund_email([order_line_reimbursement], 'rejection')
    end
  end
end
