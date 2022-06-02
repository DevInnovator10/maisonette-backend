# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::AdjustedShipmentTotal, type: :model do
  let(:order) { create(:order_ready_for_payment) }
  let(:shipment) { order.shipments.first }
  let(:shipment_adjustment) { create :adjustment, adjustable: shipment, amount: -10 }

  before do
    shipment.update!(cost: 100)
    shipment_adjustment
  end

  describe '#adjusted_shipment_total' do
    it 'reflect what the customer paid including shiping adjustments' do
      expect(order.adjusted_shipment_total).to eq(90)
    end
  end
end
