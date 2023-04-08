# frozen_string_literal: true

FactoryBot.modify do
  factory :image do
    sequence(:source_url) { |n| "image_url#{n}.jpg" }
  end
end
