# frozen_string_literal: true

FactoryBot.modify do
  factory :line_item, class: 'Spree::LineItem' do
    vendor do
      variant.prices.first&.vendor || build(:vendor)
    end

    trait :final_sale do
      final_sale { true }
    end
  end
end
