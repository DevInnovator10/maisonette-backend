# frozen_string_literal: true

FactoryBot.define do
  factory :order_item_summary, class: OrderManagement::OrderItemSummary do
    association(:sales_order)
    association(:summarable, factory: :line_item)
  end
end
