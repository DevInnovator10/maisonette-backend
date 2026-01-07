# frozen_string_literal: true

FactoryBot.modify do
  factory :option_type do
    trait :color do
      name { 'Color' }
      presentation { 'Color' }
    end
  end
end
