# frozen_string_literal: true

FactoryBot.define do
    factory :reimbursement_gift_card, class: 'Spree::Reimbursement::GiftCard' do
    association :reimbursement
    association :spree_promotion_code, factory: [:promotion_code, :with_gift_card]

    amount { 10 }
  end
end
