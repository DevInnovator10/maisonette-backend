# frozen_string_literal: true

FactoryBot.modify do
  factory :promotion, class: 'Spree::Promotion' do
    trait :with_excluded_product_in_taxon do
      transient do
        taxons { [create(:taxon)] }
      end

      after(:create) do |promotion, evaluator|
        promotion.rules.create!(
          type: 'Spree::Promotion::Rules::ExcludedTaxon',
          taxons: evaluator.taxons
        )
      end
    end

    trait :with_excluded_product do
      transient do
        products { [create(:product)] }
      end

      after(:create) do |promotion, evaluator|
        promotion.rules.create!(
          type: 'Spree::Promotion::Rules::ExcludedProduct',
          products: evaluator.products
        )
      end
    end

    trait :with_gift_card_transaction do
      after(:create) do |promotion|
        promotion.promotion_category = create(:promotion_category, name: 'GiftCards', gift_card: true)
        Spree::Promotion::Actions::CreateGiftCardTransaction.create!(promotion: promotion)
      end
    end
  end
end
