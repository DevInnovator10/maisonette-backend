# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ShippingMethod::StockLocationFilter, type: :model do
  let(:described_class) { Spree::ShippingMethod }
  let(:enum_values) do
    {
      available_to_all: 0,
      available_to_international: 1,
      available_to_domestic: 2,
      custom: 3
    }
  end

  it { is_expected.to define_enum_for(:stock_location_filter).with_values(enum_values) }

  describe '#available_to_all=' do
    subject(:update_availability!) { -> { shipping_method.update(available_to_all: available_to_all) } }

    let(:shipping_method) { create(:shipping_method) }

    context 'when available_to_all is true' do
      let(:available_to_all) { true }

      before { shipping_method.custom! }

      it { is_expected.to change(shipping_method, :available_to_all?).from(false) }
    end

    context 'when available_to_all is false' do
      let(:available_to_all) { false }

      it { is_expected.to change(shipping_method, :available_to_all?).from(true) }
    end
  end

  describe '.available_in_stock_location' do
    subject { described_class.available_in_stock_location(stock_location) }

    let(:us_country) { create(:country, iso: 'US') }
    let(:it_country) { create(:country, iso: 'IT') }
    let!(:anyone_shipping_method) { create(:shipping_method, stock_location_filter: :available_to_all) }
    let!(:international_shipping_method) do
      create(:shipping_method, stock_location_filter: :available_to_international)
    end
    let!(:domestic_shipping_method) { create(:shipping_method, stock_location_filter: :available_to_domestic) }
    let!(:custom_shipping_method) do
      create(:shipping_method, stock_location_filter: :custom, stock_locations: [other_stock_location])
    end
    let(:other_stock_location) { create :stock_location }

    context 'with domestic stock location' do
      let(:stock_location) { create :stock_location, country: us_country }

      it { is_expected.to contain_exactly anyone_shipping_method, domestic_shipping_method }
    end

    context 'with international stock location' do
      let(:stock_location) { create :stock_location, country: it_country, domestic_override: domestic_override }
      let(:domestic_override) { false }

      it { is_expected.to contain_exactly anyone_shipping_method, international_shipping_method }

      context 'when domestic override is true' do
        let(:domestic_override) { true }

        it { is_expected.to contain_exactly anyone_shipping_method, domestic_shipping_method }
      end
    end

    context 'with custom stock location from US' do
      let(:stock_location) { other_stock_location }

      it { is_expected.to contain_exactly anyone_shipping_method, custom_shipping_method, domestic_shipping_method }
    end
  end
end
