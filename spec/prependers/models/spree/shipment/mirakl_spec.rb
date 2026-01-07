# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Shipment::Mirakl, type: :model, mirakl: true do
  let(:described_class) { Spree::Shipment }

  describe 'associations' do
    it { is_expected.to have_one(:mirakl_shop).through(:stock_location) }
    it { is_expected.to have_one(:mirakl_order).class_name('Mirakl::Order') }
    it { is_expected.to have_many(:easypost_orders).class_name('Easypost::Order') }
  end

  describe 'scope :mirakl_shipments' do
    let(:order) { create :order, shipments: shipments }
    let(:shipments) { [shipment1] }
    let(:shipment1) { create :shipment, stock_location: stock_location1 }
    let(:stock_location1) { mirakl_shop1.stock_location }
    let(:mirakl_shop1) { create :mirakl_shop, :with_stock_location, shop_status: :open }

    it 'returns shipments' do
      expect(order.shipments.mirakl_shipments).to match_array([shipment1])
    end

    context 'when the shipment contains Free Shipping (Gift Cards)' do
      let(:free_shipping_rate) { shipment1.selected_shipping_rate }
      let(:free_shipping_method) { create :shipping_method, admin_name: 'Free Shipping (Gift Cards)' }

      before do
        free_shipping_rate.update(shipping_method: free_shipping_method)
      end

      it 'returns no shipments' do
        expect(order.shipments.mirakl_shipments).to be_empty
      end
    end
  end

  describe 'scope :mirakl_shipment_for_order_line' do
    let(:shipment) { create :shipment, stock_location: mirakl_shop.stock_location }
    let(:shipping_method) { create :shipping_method, mirakl_shipping_method_code: 'ground' }
    let(:mirakl_shop) { create :mirakl_shop, :with_stock_location }

    let(:shipment2) { create :shipment, stock_location: mirakl_shop.stock_location }
    let(:shipping_method2) { create :shipping_method, mirakl_shipping_method_code: 'freight' }

    before do
      shipment.shipping_methods.clear
      shipment.shipping_rates.create!(shipping_method: shipping_method, selected: true)

      shipment2.shipping_methods.clear
      shipment2.shipping_rates.create!(shipping_method: shipping_method2, selected: true)
    end

    it 'returns a shipment that matches the mirakl_shop and shipping_method' do
      expect(
        Spree::Shipment.mirakl_shipment_for_order_line(mirakl_shop.shop_id,
                                                       shipping_method.mirakl_shipping_method_code)
      ).to eq shipment

      expect(
        Spree::Shipment.mirakl_shipment_for_order_line(mirakl_shop.shop_id,
                                                       shipping_method2.mirakl_shipping_method_code)
      ).to eq shipment2
    end
  end
end
