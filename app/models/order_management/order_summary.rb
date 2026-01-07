# frozen_string_literal: true

module OrderManagement
  class OrderSummary < ApplicationRecord
    belongs_to :sales_order, optional: false

    def self.order_management_object_name
      'OrderSummary'
    end
  end
end
