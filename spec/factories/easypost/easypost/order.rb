# frozen_string_literal: true

FactoryBot.define do
  factory :easypost_order, class: Easypost::Order do
    association :spree_shipment, factory: :shipment
  end
end
