# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::RefreshAdvertisedPromotionsInteractor do
    describe '#call' do
    subject(:interactor) { described_class.call }

    let(:promotion1) { create(:promotion, starts_at: Time.zone.today + 2.days) }
    let(:promotion2) { create(:promotion, advertised_products: [product1]) }
    let(:promotion3) do
      create(
        :promotion,
        :with_promotion_rule,
        :with_promotion_action,
        starts_at: Time.zone.today + 2.days,
        code: 'CODE3',
        promotion_rule: Spree::Promotion::Rules::ExcludedProduct.new(products: [product1]),
        promotion_action: Spree::Promotion::Actions::CreateItemAdjustments.new(
          calculator: Spree::Calculator::PercentOnLineItem.new
        ),
        advertised_products: [product1, product2]
      )
    end
    let(:promotion4) do
      create(
        :promotion,
        :with_promotion_rule,
        :with_promotion_action,
        code: 'CODE4',
        promotion_rule: Spree::Promotion::Rules::ExcludedProduct.new(products: [product1, product4]),
        promotion_action: Spree::Promotion::Actions::CreateItemAdjustments.new(
          calculator: Spree::Calculator::PercentOnLineItem.new
        ),
        advertised_products: [product1, product3]
      )
    end
    let(:promotion5) do
      create(
        :promotion,
        :with_promotion_rule,
        :with_promotion_action,
        code: 'CODE5',
        promotion_rule: Spree::Promotion::Rules::ExcludedProduct.new(products: [product1, product3]),
        promotion_action: Spree::Promotion::Actions::CreateItemAdjustments.new(
          calculator: Spree::Calculator::PercentOnLineItem.new
        ),
        advertised_products: [product2, product3, product4]
      )
    end

    let(:product1) { create(:product) }
    let(:product2) { create(:product) }
    let(:product3) { create(:product) }
    let(:product4) { create(:product) }

    before do
      promotion1
      promotion2
      promotion3.reload.update(advertise: true)
      promotion4.reload.update(advertise: true)
      promotion5.reload.update(advertise: true)
    end

    it 'rebuilds the associations between products and advertised promotions' do
      interactor

      expect(promotion1.reload.advertised_product_ids).to be_empty
      expect(promotion2.reload.advertised_product_ids).to be_empty
      expect(promotion3.reload.advertised_product_ids).to be_empty
      expect(promotion4.reload.advertised_product_ids).to contain_exactly(product2.id, product3.id)
      expect(promotion5.reload.advertised_product_ids).to contain_exactly(product2.id, product4.id)
    end

    it 'touches the products that have been added or removed' do
      Timecop.freeze(Time.zone.now + 1.hour) do
        interactor

        expect(product1.reload.updated_at.to_s).to eq(Time.zone.now.to_s)
        expect(product2.reload.updated_at.to_s).to eq(Time.zone.now.to_s)
        expect(product3.reload.updated_at.to_s).to eq(Time.zone.now.to_s)
        expect(product4.reload.updated_at.to_s).not_to eq(Time.zone.now.to_s)
      end
    end
  end
end
