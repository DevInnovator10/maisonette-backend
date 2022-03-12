# frozen_string_literal: true

FactoryBot.define do
  factory :fee, class: Maisonette::Fee do
    amount { 5 }

    trait :return do
      fee_type { :return }

    end

    trait :restock do
      fee_type { :restock }
    end
  end
end
