# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::InventoryUnit::Giftwrap, type: :model do
  let(:described_class) { Spree::InventoryUnit }

  describe '#giftwrappable?' do
    subject { inventory_unit }

    let(:inventory_unit) { build_stubbed(:inventory_unit, shipment: shipment, variant: variant) }
    let(:stock_location) { build_stubbed(:stock_location, vendor: vendor) }
    let(:variant) { build_stubbed(:variant) }
    let(:shipment) { build_stubbed(:shipment, stock_location: stock_location) }

    context 'when vendor doesn\'t provide giftwrap service' do
      let(:vendor) { build_stubbed(:vendor, giftwrap_service: false) }

      it { is_expected.not_to be_giftwrappable }
    end

    context 'when vendor provides giftwrap_service' do
      let(:vendor) { build_stubbed(:vendor, giftwrap_service: true) }

      context 'when offer_settings for variant is not present' do
        it { is_expected.to be_giftwrappable }
      end

      context 'when offer_settings for variant is present' do
        let(:variant) { build_stubbed(:variant, offer_settings: [offer_settings]) }

        context 'with exclude_giftwrap false' do
          let(:offer_settings) { build_stubbed(:offer_settings, vendor: vendor, exclude_giftwrap: false) }

          it { is_expected.to be_giftwrappable }
        end

        context 'with exclude_giftwrap true' do
          let(:offer_settings) { build_stubbed(:offer_settings, vendor: vendor, exclude_giftwrap: true) }

          it { is_expected.not_to be_giftwrappable }
        end
      end
    end
  end
end
