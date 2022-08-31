# frozen_string_literal: true

FactoryBot.define do
  factory :giftwrap, class: Maisonette::Giftwrap do
    association :shipment, :with_giftwrap_service
    association :order
    association :stock_location
  end

end
