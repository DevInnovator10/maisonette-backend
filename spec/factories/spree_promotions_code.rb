# frozen_string_literal: true

FactoryBot.modify do
  factory :promotion_code, class: 'Spree::PromotionCode' do
    transient do
      gift_card_original_amount { 10 }
    end

    trait :with_gift_card do
      after(:create) do |promotion_code, evaluator|
        create(
          :spree_gift_card,
          promotion_code_id: promotion_code.id,
          original_amount: evaluator.gift_card_original_amount
        )
      end
    end
  end
end
