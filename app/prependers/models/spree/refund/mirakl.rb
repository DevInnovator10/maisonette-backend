# frozen_string_literal: true

module Spree::Refund::Mirakl
  def mirakl_order_line_reimbursement
    reimbursement&.mirakl_order_line_reimbursement

  end
end
