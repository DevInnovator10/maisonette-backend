# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Giftwrap, type: :model do
    subject { create(:giftwrap) }

  it { is_expected.to belong_to(:stock_location).class_name('Spree::StockLocation').optional }
  it { is_expected.to belong_to(:shipment).class_name('Spree::Shipment').touch(true).optional }
  it { is_expected.to belong_to(:order).optional }
  it { is_expected.to have_one(:vendor).through(:stock_location) }
  it { is_expected.to have_many(:adjustments).class_name('Spree::Adjustment').dependent(:destroy) }
  it { is_expected.to delegate_method(:estimated_giftwrap_price).to(:vendor).allow_nil }
  it { is_expected.to delegate_method(:giftwrap_cost).to(:vendor).allow_nil }
  it { is_expected.to validate_uniqueness_of(:shipment_id).allow_blank }

  describe '#giftwrap_money' do
    subject { giftwrap.giftwrap_money }

    let(:giftwrap) { build_stubbed(:giftwrap) }

    before do
      allow(giftwrap).to receive(:giftwrap_price).and_return 2.00
    end

    it { is_expected.to eq Spree::Money.new(2.00) }
  end

  describe '#giftwrap_price' do
    let(:giftwrap) { create(:giftwrap) }

    it 'is an alias of estimated_giftwrap_price' do
      expect(giftwrap.method(:giftwrap_price)).to eq giftwrap.method(:estimated_giftwrap_price)
    end
  end

  describe 'set order and stock location' do
    let(:vendor) { create(:vendor, :with_giftwrap_service) }
    let(:stock_location) { create(:stock_location, vendor: vendor) }
    let(:order) { create(:order_with_line_items, vendor: vendor) }
    let(:shipment) { create(:shipment, order: order, stock_location: stock_location) }
    let(:giftwrap) { create(:giftwrap, shipment: shipment) }

    it 'sets the order and stock location on giftwrap' do
      expect(giftwrap.order).to eq order
      expect(giftwrap.stock_location).to eq stock_location
    end
  end

  describe 'giftwrappable_shipment validation' do
    let(:shipment) { build_stubbed(:shipment) }
    let(:giftwrap) { build(:giftwrap, shipment: shipment) }

    before do
      allow(shipment).to receive(:giftwrappable?).and_return(giftwrappable)
    end

    context 'with shipment not giftwrappable' do
      let(:giftwrappable) { false }

      it { is_expected.not_to allow_value(shipment).for(:shipment) }
    end

    context 'when shipment giftwrappable' do
      let(:giftwrappable) { true }

      it { is_expected.to allow_value(shipment).for(:shipment) }
    end
  end

  describe '#giftwrap_total' do
    subject(:giftwrap_total) { giftwrap.giftwrap_total }

    let(:giftwrap) { build_stubbed(:giftwrap) }

    before do
      allow(giftwrap).to receive_messages(adjustments: adjustments)
    end

    context 'when there are eligible adjustments' do
      let(:adjustments) { class_double Spree::Adjustment, eligible: eligible_adjustments }
      let(:eligible_adjustments) { class_double Spree::Adjustment, sum: 50.5 }

      it 'returns a sum of the adjustments' do
        expect(giftwrap_total).to eq 50.5
      end
    end

    context 'when there are no eligible adjustments' do
      let(:adjustments) {}

      it 'returns 0.0' do
        expect(giftwrap_total).to eq 0.0
      end
    end
  end

  describe '#compute_amount' do
    subject { giftwrap.compute_amount(shipment.line_items.first) }

    let(:order) { create(:order_with_line_items, line_items_attributes: [{ quantity: 2 }]) }
    let(:shipment) { create(:shipment, :with_giftwrap_service, order: order, stock_location: stock_location) }
    let(:stock_location) { create(:stock_location, vendor: vendor) }
    let(:giftwrap) { create(:giftwrap, shipment: shipment) }
    let(:vendor) do
      create(
        :vendor,
        giftwrap_service: true,
        giftwrap_price: 4,
        giftwrap_cost: 1
      )
    end

    it { is_expected.to be 4.00 }

    context 'when the inventory_units related to the shipment are different than line_item#quantity' do
      before { shipment.inventory_units.last.destroy }

      it { is_expected.to be 4.00 }
    end

    context 'when shipment is related to two line_items' do
      let(:order) { create(:order_with_line_items, line_items_count: 2) }

      it { is_expected.to be 4.00 }
    end
  end

  describe 'adjustments' do
    let(:order) { create(:order_with_line_items, line_items_attributes: [{ quantity: quantity }]) }
    let(:shipment) { create(:shipment, :with_giftwrap_service, order: order, stock_location: stock_location) }
    let(:stock_location) { create(:stock_location, vendor: vendor) }
    let(:giftwrap_price) { 1.50 }
    let(:quantity) { 2 }
    let(:giftwrap) { create(:giftwrap, shipment: shipment) }
    let(:vendor) do
      create(
        :vendor,
        giftwrap_service: true,
        giftwrap_price: giftwrap_price,
        giftwrap_cost: 1
      )
    end

    before { giftwrap }

    describe 'after_create' do
      it 'adds an adjustment to the shipment' do
        shipment_adjustment = order.shipment_adjustments.first

        expect(shipment_adjustment).to have_attributes(
          amount: giftwrap_price,
          label: "Giftwrap service for shipment #{shipment.number}",
          eligible: true,
          source: giftwrap
        )
      end
    end
  end
end
