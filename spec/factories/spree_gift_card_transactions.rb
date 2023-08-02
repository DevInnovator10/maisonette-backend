# frozen_string_literal: true

FactoryBot.define do
  factory :spree_gift_card_transaction, class: 'Spree::GiftCardTransaction' do
    amount { -5 }
    action { 'redemption' }
  end
end
