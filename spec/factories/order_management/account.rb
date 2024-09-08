# frozen_string_literal: true

FactoryBot.define do
  factory :order_management_account, class: OrderManagement::Account do
    order_manageable { create(:maisonette_customer) }
  end
end
