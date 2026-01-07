# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::InventoryUnit::Kustomer, type: :model do
  let(:order) { create(:order_with_line_items) }
  let(:shipment) { create(:shipment) }

  before do
    allow(inventory_unit).to receive(:order).and_return(order)
    allow(order).to receive(:mark_out_of_sync)
    allow(order).to receive(:update!)
  end

  describe '#cancel' do
    let(:inventory_unit) { build(:inventory_unit, line_item: order.line_items.first, shipment: shipment) }

    it 'calls order.mark_out_of_sync' do
      inventory_unit.cancel!

      expect(order).to have_received(:mark_out_of_sync)
    end
  end

  describe '#return' do
    let(:inventory_unit) do
      build(:inventory_unit, state: :shipped, line_item: order.line_items.first, shipment: shipment)
    end

    it 'calls order.mark_out_of_sync' do
      inventory_unit.return!

      expect(order).to have_received(:mark_out_of_sync)
    end
  end
end
