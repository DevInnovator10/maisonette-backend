# frozen_string_literal: true

FactoryBot.define do
  factory :return_fee, class: 'Maisonette::Fee' do
    amount { 10.0 }
    fee_type { 1 }
    spree_return_authorization { create(:return_authorization) }
  end
end
