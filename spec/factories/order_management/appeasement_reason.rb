# frozen_string_literal: true

FactoryBot.define do
  factory :oms_appeasement_reason, class: OrderManagement::AppeasementReason do
    name { 'Discount sale' }
    mirakl_code { 'DISCOUNT10' }
  end
end
