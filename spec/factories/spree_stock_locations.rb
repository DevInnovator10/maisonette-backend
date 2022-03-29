# frozen_string_literal: true

FactoryBot.modify do
  factory :stock_location, class: 'Spree::StockLocation' do
    sequence(:name) { |n| "NY Warehouse #{n}" }
    association :vendor
  end
end
