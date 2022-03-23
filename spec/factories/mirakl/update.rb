# frozen_string_literal: true

FactoryBot.define do
  factory :mirakl_update, class: Mirakl::Update do
    mirakl_type { :shop }
    started_at { 2.hours.ago }

    trait :shop do
      mirakl_type { :shop }
    end

    trait :offer do
      mirakl_type { :offer }
    end

    trait :order_list do
      mirakl_type { :order_list }
    end
  end
end
