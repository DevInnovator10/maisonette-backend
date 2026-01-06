# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Stock::MarketplaceCoordinator, type: :model do
    describe '#shipments' do
    subject { -> { described_class.new(order).shipments } }

    let(:order) { create(:order_with_line_items, line_items_count: 2) }

    before do
      create(:stock_location, propagate_all_variants: true)
    end

    context 'with one line item for one variant that has 2 price from 2 different vendor' do
      let(:variant) { create(:variant, :with_multiple_prices) }

      let(:first_vendor) { variant.prices.first.vendor }
      let(:first_line_item_stock) { 0 }
      let!(:first_stock_location) { create(:stock_location, propagate_all_variants: true, vendor: first_vendor) }

      let(:second_vendor) { variant.prices.second.vendor }
      let(:second_line_item_stock) { 0 }
      let!(:second_stock_location) { create(:stock_location, propagate_all_variants: true, vendor: second_vendor) }

      let(:order) do
        create(
          :order_with_line_items,
          line_items_count: 2,
          line_items_attributes: [
            { variant: variant, vendor: first_vendor },
            { variant: variant, vendor: second_vendor },
          ]
        )
      end

      before do
        Spree::StockItem.find_by(variant_id: variant.id, stock_location_id: first_stock_location.id).tap do |si|
          si.set_count_on_hand(first_line_item_stock)
          si.update(backorderable: false)
        end

        Spree::StockItem.find_by(variant_id: variant.id, stock_location_id: second_stock_location.id).tap do |si|
          si.set_count_on_hand(second_line_item_stock)
          si.update(backorderable: false)
        end
      end

      it { is_expected.to raise_error(Spree::Order::InsufficientStock) }

      context 'when stock item have sufficient stock only in one stock item' do
        let(:first_line_item_stock) { 10 }

        it { is_expected.to raise_error(Spree::Order::InsufficientStock) }

        context 'when stock item have sufficient stock for both stock items' do
          subject { described_class.new(order).shipments.size }

          let(:second_line_item_stock) { 10 }

          it { is_expected.to eq 2 }
        end
      end

      context 'when stock item have sufficient stock in a stock location not related with the selected vendor' do
        let(:variant) do
          create(
            :variant,
            :with_multiple_prices,
            vendor_prices: [
              { vendor: create(:vendor), amount: 10 },
              { vendor: create(:vendor), amount: 10 },
              { vendor: another_vendor, amount: 10 }
            ]
          )
        end

        let(:another_vendor) { create(:vendor) }
        let(:another_line_item_stock) { 10 }
        let!(:another_stock_location) { create(:stock_location, propagate_all_variants: true, vendor: another_vendor) }

        before do
          Spree::StockItem
            .find_by(
              variant_id: variant.id,
              stock_location_id: another_stock_location.id
            )
            .set_count_on_hand(another_line_item_stock)
        end

        it { is_expected.to raise_error(Spree::Order::InsufficientStock) }
      end
    end
  end
end
