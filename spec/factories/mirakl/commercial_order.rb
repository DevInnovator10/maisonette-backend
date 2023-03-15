# frozen_string_literal: true

FactoryBot.define do
  factory :mirakl_commercial_order, class: Mirakl::CommercialOrder do
    association :spree_order, factory: :order_ready_to_ship
    commercial_order_id { spree_order.number }
  end
end
