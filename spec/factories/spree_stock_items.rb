# frozen_string_literal: true

FactoryBot.modify do
  factory :stock_item, class: 'Spree::StockItem' do
    trait :no_stock do
      after(:create) { |object| object.update_column(:count_on_hand, 0) }
    end
  end
end
