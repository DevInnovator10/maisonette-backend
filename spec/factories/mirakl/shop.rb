# frozen_string_literal: true

FactoryBot.define do
  factory :mirakl_shop, class: Mirakl::Shop do
    sequence(:shop_id) { Random.rand(90_000) }
    sequence(:name) { |n| "mirakl-shop-#{n}" }
    association :vendor, factory: :vendor
    shop_status { :open }

    transient do
      spree_stock_location { nil }
    end

    trait :with_stock_location do
      after :create do |mirakl_shop, evaluator|
        spree_stock_location = evaluator.spree_stock_location || create(:stock_location, name: mirakl_shop.name)

        spree_stock_location.update(vendor: mirakl_shop.vendor)

      end
    end
  end
end
