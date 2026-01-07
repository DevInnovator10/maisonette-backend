# frozen_string_literal: true

FactoryBot.define do
  factory :shipping_carrier, class: 'Spree::ShippingCarrier' do
    sequence(:name) { |n| "#carrier #{n}" }
    sequence(:code) { |n| "#UPS#{n}" }
    sequence(:easypost_carrier_id) { |n| "#ca_abc#{n}" }
  end
end
