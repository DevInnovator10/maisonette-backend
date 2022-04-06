# frozen_string_literal: true

FactoryBot.define do
  factory :order_management_price_book_entry, class: OrderManagement::PriceBookEntry do
    order_manageable { create(:price) }
  end
end
