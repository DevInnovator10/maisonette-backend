# frozen_string_literal: true

FactoryBot.modify do
  factory :order_ready_to_ship do
    trait :with_line_items do
      line_items do
        Array.new(3) { build(:line_item) }
      end
    end
  end
end
