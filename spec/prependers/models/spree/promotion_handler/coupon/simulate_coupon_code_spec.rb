# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionHandler::Coupon::SimulateCouponCode, type: :model do
  let(:described_class) { Spree::PromotionHandler::Coupon }

  let(:coupon_handler) { described_class.new(order) }
  let(:order) { create(:completed_order_with_totals) }

  let(:promotion) { create(:promotion, :with_order_adjustment) }
  let(:promotion_code) { create :promotion_code, promotion: promotion }
  let(:coupon_code) { promotion_code.value }

  describe '#simulate_coupon_code' do
    subject(:promotion_adjustments) { coupon_handler.simulate_coupon_code(coupon_code) }

    before { allow(coupon_handler).to receive(:promotion_code).and_return promotion_code }

    it 'returns the adjustments' do
      expect(promotion_adjustments).to all(be_an(Spree::Adjustment))
    end

    context 'when a promotion_code is inactive' do
      before { allow(promotion_code).to receive(:inactive?).and_return true }

      it 'returns the ajustments related to the promotion' do
        expect(promotion_adjustments).to be_empty
      end
    end

    context 'when the promotion creates shipments, order and line item adjustments' do
      before do
        calculator = Spree::Calculator::FlatRate.new
        calculator.preferred_amount = 1
        Spree::Promotion::Actions::CreateItemAdjustments.create!(calculator: calculator, promotion: promotion)
        Spree::Promotion::Actions::FreeShipping.create!(promotion: promotion)
      end

      it 'returns 3 adjustments' do
        expect(promotion_adjustments.count).to eq 3
      end

      it 'returns an adjustment at order level' do
        expect(promotion_adjustments.detect { |adj| adj.adjustable_type == 'Spree::Order' }).to be_present
      end

      it 'returns an adjustment at line item level' do
        expect(promotion_adjustments.detect { |adj| adj.adjustable_type == 'Spree::LineItem' }).to be_present
      end

      it 'returns an adjustment at shipment level' do
        expect(promotion_adjustments.detect { |adj| adj.adjustable_type == 'Spree::Shipment' }).to be_present
      end
    end

    context 'when the order contains other adjustments' do
      let(:other_promotion) { create(:promotion) }

      before do
        create(:adjustment, order: order, source_type: 'Spree::TaxRate', source_id: 1)
        create(:adjustment, order: order, source: other_promotion)
      end

      it 'returns only one adjustment' do
        expect(promotion_adjustments.count).to eq 1
      end

      it 'returns only adjustment promo' do
        expect(promotion_adjustments).to all(be_promotion)
      end

      it 'returns only adjustment related to the current promotion' do
        expect(promotion_adjustments).to all(have_attributes(promotion_code: promotion_code))
      end

      it 'returns not persisted adjustments' do
        expect(promotion_adjustments).to be_none(&:persisted?)
      end

      it "doesn't update the order" do
        expect { promotion_adjustments }.not_to(change { order.reload.updated_at })
      end

      it "doesn't update the adjustments" do
        expect { promotion_adjustments }.not_to(change { order.reload.adjustment_ids })
      end
    end
  end
end
