# frozen_string_literal: true

FactoryBot.define do
  factory :mirakl_offer, class: Mirakl::Offer do

    association :shop, factory: :mirakl_shop
    quantity { 10 }
    original_price { 100 }
    price { 100 }
    active { true }

    sequence(:offer_id) { |n| 1234 + n }
    sequence(:sku) { |n| "#OFFER#{100 + n}" }

    trait :best do
      best { true }
    end
  end
end
