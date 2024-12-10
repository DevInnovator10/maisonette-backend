# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Shipment::Giftwrap, type: :model do
  let(:described_class) { Spree::Shipment }

  it { is_expected.to have_one(:giftwrap).class_name('Maisonette::Giftwrap').dependent(:nullify) }
  it { is_expected.to accept_nested_attributes_for(:giftwrap) }
  it { is_expected.to delegate_method(:giftwrap_service?).to(:vendor) }
  it { is_expected.to delegate_method(:estimated_giftwrap_price).to(:vendor) }

  describe 'when shipment with giftwrap is destroyed' do
    subject(:destroy_shipment) { shipment.destroy }

    let(:vendor) { create(:vendor, :with_giftwrap_service) }
    let(:giftwrap) { create(:giftwrap, shipment: shipment) }
    let(:shipping_method) { create(:shipping_method) }
    let(:shipment) { create(:shipment, :with_giftwrap_service, shipping_method: shipping_method) }
    let(:order) { shipment.order }

    before { giftwrap }

    it 'destroyes the adjustments related to the giftwrap' do
      expect { destroy_shipment }.to change { giftwrap.adjustments.count }.from(1).to(0)
    end

    it 'preserves the giftwrap but removes the shipment id' do
      expect(giftwrap.reload).to have_attributes(
        shipment_id: shipment.id
      )

      destroy_shipment

      expect(giftwrap.reload).to have_attributes(
        shipment_id: nil
      )
    end
  end

  describe '#giftwrappable?' do
    subject { shipment.giftwrappable? }

    let(:vendor) { build_stubbed(:vendor, giftwrap_service: true) }
    let(:stock_location) { build_stubbed(:stock_location, vendor: vendor) }
    let(:shipment) { build_stubbed(:shipment, stock_location: stock_location) }

    before do
      allow(shipment).to receive(:inventory_units).and_return(inventory_units)
    end

    context 'when inventory_units is nil' do
      let(:inventory_units) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when inventory_units is an array' do
      context 'when empty' do
        let(:inventory_units) { [] }

        it { is_expected.to be_falsey }
      end

      context 'when not empty' do
        let(:inventory_units) { [first_inventory_unit, second_inventory_unit] }
        let(:first_inventory_unit) { instance_double(Spree::InventoryUnit, 'giftwrappable?' => true) }

        context 'when all are giftwrappable' do
          let(:second_inventory_unit) { instance_double(Spree::InventoryUnit, 'giftwrappable?' => true) }

          it { is_expected.to be_truthy }
        end

        context 'when at least one is not giftwrappable' do
          let(:second_inventory_unit) { instance_double(Spree::InventoryUnit, 'giftwrappable?' => false) }

          it { is_expected.to be_falsey }
        end
      end
    end
  end
end
