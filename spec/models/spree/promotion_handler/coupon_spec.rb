# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionHandler::Coupon, type: :model do
  subject(:coupon) { described_class.new(order) }

  let(:order) { create(:order, state: 'delivery', coupon_code: code) }
  let(:code) { '10off' }

  def expect_order_connection(order:, promotion:, promotion_code: nil)
    expect(order.promotions.to_a).to include(promotion)
    expect(order.order_promotions.flat_map(&:promotion_code)).to include(promotion_code)
  end

  def expect_adjustment_creation(adjustable:, promotion:, promotion_code: nil)
    expect(adjustable.adjustments.map(&:source).map(&:promotion)).to include(promotion)
    expect(adjustable.adjustments.map(&:promotion_code)).to include(promotion_code)
  end

  it 'returns self in apply' do
    expect(coupon.apply).to be_a described_class
  end

  context 'when coupon code promotion doesnt exist' do
    before { create(:promotion) }

    it 'doesnt fetch any promotion' do
      expect(coupon.promotion).to be_blank
    end

    context 'with no actions defined' do
      before { create(:promotion, code: code) }

      it 'populates error message' do
        coupon.apply

        expect(coupon.error).to eq I18n.t('spree.coupon_code_not_found')
      end
    end
  end

  context 'when existing coupon code promotion' do
    let!(:promotion) { promotion_code.promotion }
    let(:promotion_code) { create(:promotion_code, value: code) }
    let(:calculator) { Spree::Calculator::FlatRate.new(preferred_amount: 10) }
    let(:action) do
      Spree::Promotion::Actions::CreateItemAdjustments.create(promotion: promotion, calculator: calculator)
    end

    before do
      promotion_code.promotion
      action
    end

    it 'fetches with given code' do
      expect(coupon.promotion).to eq promotion
    end

    context 'with a per-item adjustment action' do
      let(:order) { create(:order_with_line_items, line_items_count: 3, state: 'delivery') }

      context 'when right coupon given' do
        context 'with correct coupon code casing' do
          before { order.coupon_code = code }

          it 'successfully activates promo' do
            expect(order.total).to eq(130)
            coupon.apply
            expect(coupon.success).to be_present
            expect_order_connection(order: order, promotion: promotion, promotion_code: promotion_code)
            order.line_items.each do |line_item|
              expect_adjustment_creation(adjustable: line_item, promotion: promotion, promotion_code: promotion_code)
            end
            # Ensure that applying the adjustment actually affects the order's total!
            expect(order.reload.total).to eq(100)
          end

          it 'coupon already applied to the order' do
            coupon.apply
            expect(coupon.success).to be_present
            coupon.apply
            expect(coupon.error).to eq I18n.t('spree.coupon_code_already_applied')
          end
        end

        # Regression test for https://github.com/spree/spree/issues/4211
        context 'with incorrect coupon code casing' do
          before { order.coupon_code = '10OFF' }

          it 'successfully activates promo' do
            expect(order.total).to eq(130)
            coupon.apply
            expect(coupon.success).to be_present
            expect_order_connection(order: order, promotion: promotion, promotion_code: promotion_code)
            order.line_items.each do |line_item|
              expect_adjustment_creation(adjustable: line_item, promotion: promotion, promotion_code: promotion_code)
            end
            # Ensure that applying the adjustment actually affects the order's total!
            expect(order.reload.total).to eq(100)
          end
        end
      end

      context 'when coexists with a non coupon code promo' do
        let!(:order) { create(:order, state: 'delivery') }
        let(:variant) { create :variant, prices: [price] }
        let(:price) { create :price, amount: 500, vendor: create(:vendor) }
        let(:vendor) { price.vendor }

        before do
          order.coupon_code = code
          calculator = Spree::Calculator::FlatRate.new(preferred_amount: 10)
          general_promo = create(:promotion, apply_automatically: true, name: 'General Promo')
          Spree::Promotion::Actions::CreateItemAdjustments.create(promotion: general_promo, calculator: calculator)

          order.contents.add(variant, 1, options: { vendor_id: vendor.id })
          order.state = 'delivery'
        end

        # regression spec for https://github.com/spree/spree/issues/4515
        it 'successfully activates promo' do
          coupon.apply
          expect(coupon).to be_successful
          expect_order_connection(order: order, promotion: promotion, promotion_code: promotion_code)
          order.line_items.each do |line_item|
            expect_adjustment_creation(adjustable: line_item, promotion: promotion, promotion_code: promotion_code)
          end
        end
      end

      context 'when applied alongside another valid promotion ' do
        let!(:order) { create(:order) }
        let(:variant1) { create :variant, prices: [price1] }
        let(:variant2) { create :variant, prices: [price2] }
        let(:price1) { create :price, amount: 500, vendor: create(:vendor) }
        let(:price2) { create :price, amount: 10, vendor: create(:vendor) }
        let(:vendor1) { price1.vendor }
        let(:vendor2) { price2.vendor }

        before do
          order.coupon_code = code
          calculator = Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)
          general_promo = create(:promotion, apply_automatically: true, name: 'General Promo')
          Spree::Promotion::Actions::CreateItemAdjustments.create!(promotion: general_promo, calculator: calculator)

          order.contents.add(variant1, 1, options: { vendor_id: vendor1.id })
          order.contents.add(variant2, 1, options: { vendor_id: vendor2.id })

          order.state = 'delivery'

          Spree::PromotionHandler::Cart.new(order).activate
        end

        it 'successfully activates both promotions and returns success' do
          coupon.apply
          expect(coupon).to be_successful
          order.line_items.each do |line_item|
            expect(line_item.adjustments.count).to eq 2
            expect_adjustment_creation(adjustable: line_item, promotion: promotion, promotion_code: promotion_code)
          end
        end
      end
    end

    context 'with a free-shipping adjustment action' do
      before do
        Spree::Promotion::Actions::FreeShipping.create!(promotion: promotion)
      end

      context 'when right coupon code given' do
        let(:order) { create(:order_with_line_items, line_items_count: 3, state: 'delivery') }

        before { order.coupon_code = code }

        it 'successfully activates promo' do
          expect(order.total).to eq(130)
          coupon.apply
          expect(coupon.success).to be_present

          expect_order_connection(order: order, promotion: promotion, promotion_code: promotion_code)
          order.shipments.each do |shipment|
            expect_adjustment_creation(adjustable: shipment, promotion: promotion, promotion_code: promotion_code)
          end
        end

        it 'coupon already applied to the order' do
          coupon.apply
          expect(coupon.success).to be_present
          coupon.apply
          expect(coupon.error).to eq I18n.t('spree.coupon_code_already_applied')
        end
      end
    end

    context 'with a whole-order adjustment action' do
      let!(:action) { Spree::Promotion::Actions::CreateAdjustment.create(promotion: promotion, calculator: calculator) }

      context 'when right coupon given' do
        let(:order) { create(:order, state: 'delivery') }
        let(:calculator) { Spree::Calculator::FlatRate.new(preferred_amount: 10) }

        before do
          action
          allow(order).to receive_messages(
            coupon_code: code,
            # These need to be here so that promotion adjustment "wins"
            item_total: 50,
            ship_total: 10
          )
        end

        it 'successfully activates promo' do
          coupon.apply
          expect(coupon.success).to be_present
          expect(order.adjustments.count).to eq(1)
          expect_order_connection(order: order, promotion: promotion, promotion_code: promotion_code)
          expect_adjustment_creation(adjustable: order, promotion: promotion, promotion_code: promotion_code)
        end

        context 'when the coupon is already applied to the order' do
          before { coupon.apply }

          it 'is not successful' do
            coupon.apply
            expect(coupon.successful?).to be false
          end

          it 'returns a coupon has already been applied error' do
            coupon.apply
            expect(coupon.error).to eq I18n.t('spree.coupon_code_already_applied')
          end

          context 'when coupon is a gift card' do
            let(:promotion_code) do
              instance_double(
                Spree::PromotionCode,
                promotion: promotion,
                inactive?: false,
                usage_limit_exceeded?: false
              )
            end
            let(:promotion) do
              instance_double(
                Spree::Promotion,
                gift_card?: true,
                eligible?: true,
                active?: true,
                actions: action,
                usage_limit_exceeded?: false
              )
            end
            let(:action) { class_double(Spree::Promotion::Actions::CreateAdjustment, exists?: true) }

            before do
              allow(promotion).to receive(:activate).and_return(true)
              allow(Spree::PromotionCode).to receive(:where) { [promotion_code] }
            end

            it 'applies if promotions is already present in the order' do
              coupon.apply

              expect(coupon.success).to eq I18n.t('spree.coupon_code_applied')
            end
          end
        end

        context 'when the coupon fails to activate' do
          let(:promotion_code) do
            instance_double(Spree::PromotionCode, promotion: promotion, inactive?: false, usage_limit_exceeded?: false)
          end
          let(:promotion) do
            instance_double(
              Spree::Promotion,
              eligible?: true,
              active?: true,
              actions: action,
              usage_limit_exceeded?: false
            )
          end
          let(:action) { class_double(Spree::Promotion::Actions::CreateAdjustment, exists?: true) }

          before do
            allow(promotion).to receive(:activate).and_return(false)
            allow(Spree::PromotionCode).to receive(:where) { [promotion_code] }
          end

          it 'is not successful' do
            coupon.apply
            expect(coupon.successful?).to be false
          end

          it 'returns a coupon failed to activate error' do
            coupon.apply
            expect(coupon.error).to eq I18n.t('spree.coupon_code_unknown_error')
          end
        end

        context 'when the promotion exceeds its usage limit' do
          let!(:second_order) do
            create(:order_with_line_items, :completed_order_with_promotion, promotion: promotion)
          end

          before do
            promotion.update!(usage_limit: 1)
            described_class.new(second_order).apply
          end

          it 'is not successful' do
            coupon.apply
            expect(coupon.successful?).to be false
          end

          it 'returns a coupon is at max usage error' do
            coupon.apply
            expect(coupon.error).to eq I18n.t('spree.coupon_code_max_usage')
          end
        end
      end
    end
  end

  context 'when removing a coupon code from an order' do
    let!(:promotion) { promotion_code.promotion }
    let(:promotion_code) { create(:promotion_code, value: code) }
    let(:action) do
      Spree::Promotion::Actions::CreateItemAdjustments.create(promotion: promotion, calculator: calculator)
    end
    let(:calculator) { Spree::Calculator::FlatRate.new(preferred_amount: 10) }
    let(:order) { create(:order_with_line_items, line_items_count: 3, state: 'delivery') }

    context 'with an already applied coupon' do
      before do
        action
        order.coupon_code = code
        coupon.apply
        order.reload
      end

      it 'successfully removes the coupon code from the order' do
        expect(order.total).to eq(100)
        coupon.remove
        expect(coupon.error).to eq nil
        expect(coupon.success).to eq I18n.t('spree.coupon_code_removed')
        expect(order.reload.total).to eq(130)
      end
    end

    context 'with a coupon code not applied to an order' do
      before do
        order.coupon_code = code
      end

      it 'returns an error' do
        expect(order.total).to eq(130)
        coupon.remove
        expect(coupon.success).to eq nil
        expect(coupon.error).to eq I18n.t('spree.coupon_code_not_present')
        expect(order.reload.total).to eq(130)
      end
    end
  end
end
