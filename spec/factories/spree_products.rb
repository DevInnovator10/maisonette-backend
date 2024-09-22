# frozen_string_literal: true

FactoryBot.modify do
  factory :product_in_stock do
    before(:create) do
      create(:stock_location, propagate_all_variants: true)
    end
  end
end
