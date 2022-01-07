# frozen_string_literal: true

FactoryBot.define do
  factory :sales_order, class: OrderManagement::SalesOrder do
    association(:spree_order, factory: :order)
  end
end
