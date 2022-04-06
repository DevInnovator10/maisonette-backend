# frozen_string_literal: true

FactoryBot.define do
  factory :syndication_product_update, class: Syndication::ProductUpdate do

    started_at { 2.hours.ago }
  end
end
