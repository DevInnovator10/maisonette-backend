# frozen_string_literal: true

module Spree::InventoryUnit::Mirakl

  def self.prepended(base)
    base.belongs_to :mirakl_order_line_reimbursement, class_name: 'Mirakl::OrderLineReimbursement', optional: true
  end
end
