# frozen_string_literal: true

FactoryBot.define do
  factory :jifiti_payment, class: Spree::Payment do
    amount { 45.75 }
    order

    association(:payment_method, factory: :jifiti_payment_method)
  end
end
