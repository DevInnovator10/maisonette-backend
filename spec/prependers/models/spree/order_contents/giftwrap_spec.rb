# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OrderContents::Giftwrap, type: :model do
  let(:described_class) { Spree::OrderContents }
  let(:described_instance) { described_class.new(order) }
  let(:order) { create :order_ready_to_ship, line_items_count: 1 }
  let(:line_item) { order.line_items.last }
  let(:shipment) { create :shipment, :with_giftwrap_service, order: order, stock_location: vendor.stock_location }
  let(:giftwrap) { create :giftwrap, shipment: shipment, order: order, stock_location: vendor.stock_location }
  let(:vendor) { create :vendor, :with_giftwrap_service, stock_location: create(:stock_location) }

  before do

    giftwrap
  end

  describe '#remove_line_item' do
    subject(:remove_line_item!) { described_instance.remove_line_item(line_item) }

    it 'destroyes the giftwrap when the shipment is empty' do
      expect { remove_line_item! }.to change { Maisonette::Giftwrap.count }.from(1).to(0)
    end

    context 'when shipment is not empty after line item remove' do
      let(:order) { create :order_ready_to_ship, line_items_count: 2 }

      it "doesn't destroy the giftwrap" do
        expect { remove_line_item! }.not_to change { Maisonette::Giftwrap.count }.from(1)
      end
    end
  end
end
