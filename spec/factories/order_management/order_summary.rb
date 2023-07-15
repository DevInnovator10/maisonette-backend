# frozen_string_literal: true

FactoryBot.define do
    factory :order_summary, class: OrderManagement::OrderSummary do
    association(:sales_order)
  end
end
