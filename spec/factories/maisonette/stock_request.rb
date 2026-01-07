# frozen_string_literal: true

FactoryBot.define do
  factory :stock_request, class: Maisonette::StockRequest do
    email { FFaker::Internet.email }
    variant { create :variant }
  end

end
