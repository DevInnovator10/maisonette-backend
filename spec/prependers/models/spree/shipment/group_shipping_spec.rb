# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Shipment::GroupShipping, type: :model do
  let(:shipment) { create(:shipment) }
  let(:other_shipping_rate) { shipment.shipping_rates.create(shipping_method: create(:shipping_method), cost: 19.95) }
  let(:order) { shipment.order }

  before do
    allow(shipment).to receive(:order).and_return(order)
    allow(order).to receive(:reload).and_return(order)
    allow(order).to receive(:apply_shipping_promotions)
  end

  describe '#selected_shipping_rate_id=' do
    subject(:change_shipping_rate!) { shipment.selected_shipping_rate_id = other_shipping_rate.id }

    it 'calls apply_shipping_promotions on order' do
      change_shipping_rate!

      expect(order).to have_received(:apply_shipping_promotions)
    end
  end
end
