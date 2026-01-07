# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OrderContents::Vendor, type: :model do
  let(:described_class) { Spree::OrderContents }
  let(:described_instance) { described_class.new(order) }
  let(:order) { create :order_ready_to_ship, line_items_count: 1 }
  let(:line_item) { order.line_items.last }
  let(:variant) { line_item.variant }
  let(:quantity) { 1 }
  let(:shipment) { create :shipment, order: order, stock_location: vendor.stock_location }
  let(:vendor) { create :vendor, stock_location: create(:stock_location) }
  let(:price) { create :price, vendor: vendor }
  let(:item) { create(:stock_item, stock_location: vendor.stock_location) }

  before do
    # We want to check that when passing shipment to
    # Spree::OrderContent#add/remove the `order.find_line_item_by_variant` will receive
    # also `vendor_id`, extracted from the shipment.
    # Check for Spree::Order#item_from_same_vendor at app/prependers/models/spree/order/marketplace.rb
    allow(order).to receive(:find_line_item_by_variant).and_return(line_item)

    variant.prices << price
    variant.stock_items << item
  end

  describe '#add' do
    subject(:add_item!) { described_instance.add(variant, 4, shipment: shipment) }

    context 'when shipment param is provided' do
      it 'select the correct line item according to selected shipment/vendor' do
        add_item!
        expect(order).to have_received(:find_line_item_by_variant)
          .with(variant, shipment: shipment, options: { vendor_id: vendor.id })
      end
    end
  end

  describe '#remove' do
    subject(:remove_item!) { described_instance.remove(variant, 6, shipment: shipment) }

    context 'when shipment param is provided' do
      it 'select the correct line item according to selected shipment/vendor' do
        remove_item!
        expect(order).to have_received(:find_line_item_by_variant)
          .with(variant, shipment: shipment, options: { vendor_id: vendor.id })
      end
    end
  end

end
