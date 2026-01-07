# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Promotion::Actions::FreeFlatRateAmountShipping, type: :model do
  let(:order) { create(:order_ready_for_payment) }
  let(:shipment) { order.shipments.to_a.first }
  let(:payload) { { order: order } }
  let(:shipping_method) { shipment.shipping_method }
  let(:restricted_shipping_method) { [shipping_method] }

  let(:action) { described_class.new }
  let(:rule) { Spree::Promotion::Rules::RestrictShipping.new }
  let(:promotion) do
    create(:promotion, :with_promotion_action, :with_promotion_rule, promotion_action: action, promotion_rule: rule)
  end

  let(:fetch_adjustment) { order.shipment_adjustments.where(source: action) }

  before do
    shipping_method.update!(base_flat_rate_amount: 9.95)
    promotion
    restricted_shipping_method.each do |method|
      method.promotion_rules << [rule]
    end
  end

  describe '#perform' do
    context 'when there is only one shipments' do
      it 'adds the adjustment' do
        expect(order.shipment_adjustments.count).to eq(0)
        expect(action.perform(payload)).to be_truthy
        expect(order.shipment_adjustments.count).to eq(1)
        expect(fetch_adjustment.first.amount).to eq(-shipping_method.base_flat_rate_amount)
      end
    end

    context 'when there is another shipment that matches the shipping method' do
      let(:cheapest_flat_rate_shipping_method_amount) { shipping_method.base_flat_rate_amount }
      let(:expensive_flat_rate_shipment) { create(:shipment) }
      let(:restricted_shipping_method) { [shipping_method, expensive_flat_rate_shipment.shipping_method] }

      before do
        expensive_flat_rate_shipment.shipping_method.update!(base_flat_rate_amount:
                                                               cheapest_flat_rate_shipping_method_amount + 1)
        order.shipments << expensive_flat_rate_shipment
      end

      it 'adjusts the most expensive flat rate shipment to by the flat rate amount' do
        expect(order.shipment_adjustments.count).to eq(0)

        expect(action.perform(payload)).to be_truthy
        expect(order.shipment_adjustments.count).to eq(1)
        expect(fetch_adjustment.first.amount).to eq(-expensive_flat_rate_shipment.shipping_method.base_flat_rate_amount)
      end
    end
  end

  describe '#compute_amount' do
    it 'adjusts the shipment by the base flat rate amount' do
      expect(action.compute_amount(shipment)).to eq(-shipment.shipping_method.base_flat_rate_amount)
    end
  end
end
