# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Promotion::Actions::DetractOtherShippingCost, type: :model do
    let(:order) { create(:order_ready_for_payment) }
  let(:expedited_shipment) { order.shipments.to_a.first }
  let(:payload) { { order: order } }
  let(:expedited_shipping_method) { expedited_shipment.shipping_method }
  let(:flat_rate_shipment) { create(:shipment) }
  let(:restricted_shipping_method) { expedited_shipping_method }
  let(:flat_rate_shipping_method) { create(:shipping_method) }

  let(:action) { described_class.new }
  let(:rule) { Spree::Promotion::Rules::RestrictShipping.new(preferred_name: 'expedited_shipping') }
  let(:promotion) do
    create(:promotion, :with_promotion_action, :with_promotion_rule, promotion_action: action, promotion_rule: rule)
  end

  let(:promotion_action) { Spree::Promotion::Actions::GroupShipping.new }
  let(:promotion_rule) { Spree::Promotion::Rules::RestrictShipping.new(preferred_name: 'ground') }
  let(:group_shipping_promotion) do
    promo_data = { promotion_action: promotion_action, promotion_rule: promotion_rule }
    create(:promotion, :with_promotion_action, :with_promotion_rule, promo_data)
  end

  let(:fetch_adjustment) { order.shipment_adjustments.where(source: action) }

  before do
    promotion
    restricted_shipping_method.promotion_rules << [rule]
    group_shipping_promotion
    flat_rate_shipping_method.promotion_rules << [promotion_rule]
    expedited_shipping_method.update!(base_flat_rate_amount: 9.95)
    order
    promotion.promotion_actions << action
  end

  describe '#perform' do
    context 'with one expedited shipment' do
      it 'does add the adjustment for 0.0' do
        expect(fetch_adjustment.any?).to be false
        expect(action.perform(payload)).to be_truthy
        expect(fetch_adjustment.reload.count).to eq 1
        expect(fetch_adjustment.first.amount.to_f).to eq(0.0)
      end
    end

    context 'with two expedited shipment' do
      let(:second_expedited_shipment) { create(:shipment, shipping_method: expedited_shipping_method) }

      before { order.shipments << second_expedited_shipment }

      it 'detracts the base_flat_rate_amount from one shipment' do
        expect(fetch_adjustment.any?).to be false
        expect(action.perform(payload)).to be_truthy
        expect(fetch_adjustment.reload.count).to eq 2
        expect(fetch_adjustment.map(&:amount).map(&:to_f)).to contain_exactly(0, -9.95)
      end

      context 'when the first shipment is removed' do
        it 'removes the adjustment' do
          expect(action.perform(payload)).to be_truthy
          expect(fetch_adjustment.reload.count).to eq 2
          expedited_shipment.destroy!
          expect(action.perform(payload)).to be_truthy
          expect(fetch_adjustment.reload.count).to eq 1
          expect(fetch_adjustment.first.amount.to_f).to eq(0.0)
        end
      end
    end

    context 'with two shipments and one with flat_rate that matches the action' do
      let(:flat_rate_shipment) { create(:shipment, shipping_method: flat_rate_shipping_method, cost: 50.0) }

      before { order.shipments << flat_rate_shipment }

      it 'detracts the cost from the matched shipment' do
        expect(fetch_adjustment.any?).to be false
        expect(action.perform(payload)).to be_truthy
        expect(fetch_adjustment.reload.count).to eq 1

        expect(fetch_adjustment.first.amount.to_f).to eq(-9.95)
      end

      context 'when flat_rate_shipment is adjusted to 0' do
        before do
          flat_rate_shipment.adjustments.create!(
            amount: -flat_rate_shipment.cost,
            eligible: true,
            label: 'Adjustment',
            order: flat_rate_shipment.order,
            source: create(:promotion, :with_free_shipping_adjustment).actions.first
          )
          order.recalculate
        end

        it "doesn't detract the cost because the flat rate shipment is free" do
          expect(order.shipment_adjustments.count).to eq(1)
          expect(action.perform(payload)).to be_truthy
          order.reload.recalculate
          expect(order.reload.shipment_adjustments.count).to eq(2)
          expect(flat_rate_shipment.reload.adjustments.first.amount).to eq(-flat_rate_shipment.cost)
        end
      end
    end
  end
end
