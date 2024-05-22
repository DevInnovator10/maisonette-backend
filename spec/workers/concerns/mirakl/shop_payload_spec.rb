# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ShopPayload, mirakl: true do
  let(:described_class) { FakeImportShopWorker }
  let(:shop_formatter) { described_class.new(payload).send :shop_formatter }
  let(:expected_result) do
    { shop_status: 'Open', shop_id: '1234',
      shop_name: 'Maisonette',
      operator_internal_id: 'Mais',
      description: 'description',
      country_id: country_id,
      premium: true,
      street1: '55 Washington Street',
      street2: 'unit 55',
      city: 'Brooklyn',
      state_id: state.id,
      zip_code: '11201',
      phone: '123598123',
      title: 'Mr',
      first_name: 'Bob',
      last_name: 'Marley',
      email: 'bobs@email.com' }
  end

  let(:payload) do
    { shop_state: 'Open', shop_id: '1234',
      shop_name: 'Maisonette',
      operator_internal_id: 'Mais',
      description: 'description',
      premium: true,
      shipping_country: country_iso3,
      useless: 'information',
      contact_informations: { street1: '55 Washington Street',
                              street2: 'unit 55',
                              city: 'Brooklyn',
                              state: state_name,
                              zip_code: '11201',
                              phone: '123598123',
                              civility: 'Mr',
                              firstname: 'Bob',
                              lastname: 'Marley',
                              email: 'bobs@email.com' },
      shop_additional_fields: shop_additional_fields,
      pro_details: pro_details }
  end

  let(:country_iso3) { 'USA' }
  let(:country_id) { 11 }
  let(:shop_additional_fields) { [] }
  let(:pro_details) { nil }
  let(:state_name) { 'New York' }
  let(:country) { instance_double(Spree::Country, id: country_id, states: states) }
  let(:states) { class_double(Spree::State) }
  let(:state) { instance_double(Spree::State, name: 'New York', abbr: 'NY', id: 55) }

  describe '#from_wire' do
    before do
      allow(Spree::Country).to(receive(:find_by).with(iso3: country_iso3).and_return(country))
      allow(states).to(receive(:find_by).with('lower(name) = ?', state_name.downcase).and_return(state))
    end

    context 'when country is returned' do
      it 'returns a hash with useful shop infos' do
        expect(shop_formatter).to eq(expected_result)
      end
    end

    context 'when state abbr is used' do
      let(:state_name) { 'NY' }

      before do
        allow(Spree::State).to(receive(:where).with('lower(abbr) = ?', state_name.downcase).and_return([state]))
      end

      it 'finds the state by abbr instead of name' do
        expect(shop_formatter[:state_id]).to eq(state.id)
      end
    end

    context 'when additional fields are returned' do
      let(:expected_result_with_addition_fields) do
        expected_result.merge(expected_additional_fields)
      end
      let(:expected_additional_fields) do
        { gift_wrapping: false,
          generate_returns_label: false,
          manage_own_shipping: true,
          nexus_liability: 'International',
          send_shipping_charges: false }
      end

      let(:shop_additional_fields) do
        [{ 'code': 'gift-wrapping',
           'type': 'BOOLEAN',
           'value': 'false' },
         { 'code': 'manage-own-shipping',
           'type': 'BOOLEAN',
           'value': 'true' },
         { 'code': 'nexus-liability',
           'type': 'LIST',
           'value': 'International' },
         { 'code': 'send-shipping-charges',
           'type': 'BOOLEAN',
           'value': 'false' },
         { 'code': 'generate-returns-label',
           'type': 'BOOLEAN',
           'value': 'false' }]
      end

      it 'returns a hash with the additional fields' do
        expect(shop_formatter).to eq(expected_result_with_addition_fields)
      end
    end

    context 'when the pro details are available' do
      let(:pro_details) do
        { tax_identification_number: tax_identification_number,
          identification_number: identification_number }
      end
      let(:tax_identification_number) { '12-32165489' }
      let(:identification_number) { 'EE420000004' }

      it 'contains the tax_identification_number' do
        expect(shop_formatter[:tax_id_number]).to eq(tax_identification_number)
      end

      it 'contains the identification_number' do
        expect(shop_formatter[:business_reg_number]).to eq(identification_number)
      end
    end
  end

  describe '#country' do
    subject(:country_method) { described_class.new('foo').send(:country, country_string) }

    let(:country_iso3) { 'GBR' }
    let!(:default_country) { create :country, iso3: 'USA', iso: 'US' }
    let!(:country) { create :country, iso3: country_iso3, iso: 'GB' }

    context 'when country is found' do
      let(:country_string) { country_iso3 }

      it 'returns the country' do
        expect(country_method).to eq(country)
      end
    end

    context 'when country is not found' do
      let(:country_string) { 'FOO' }

      it 'returns the default country' do
        expect(country_method).to eq(default_country)
      end
    end

    context 'when country string is nil' do
      let(:country_string) { nil }

      it 'returns the default country' do
        expect(country_method).to eq(default_country)
      end
    end
  end

  describe '#state' do
    subject(:state_method) { described_class.new(shop_hash).send(:state, state_name, country) }

    let(:shop_hash) do
      { contact_informations: { state: state_name } }.with_indifferent_access
    end

    let(:state) { create :state, name: 'New York', abbr: 'NY' }
    let(:country) { state.country }
    let(:state_not_found_message) do
      { message: 'Mirakl Shop Sync: Unable to find state ',
        state: state_name,
        shop: shop_hash }
    end

    before do
      allow(Rails.logger).to receive(:warn)

      state_method
    end

    context 'when state abbr is used' do
      let(:state_name) { 'NY' }

      it 'returns the state in relation to the given country' do
        expect(state_method).to eq(state)
      end
    end

    context 'when state name is used' do
      let(:state_name) { 'New York' }

      it 'returns the state in relation to the given country' do
        expect(state_method).to eq(state)
      end
    end

    context 'when the state is not found' do
      let(:state_name) { 'foo' }

      it 'logs a warning' do
        expect(Rails.logger).to have_received(:warn).with(state_not_found_message)
      end

      it 'returns the nil' do
        expect(state_method).to eq(nil)
      end
    end

    context 'when the state is not found due to mismatch country' do
      let(:country) { create :country }
      let(:state_name) { 'NY' }

      it 'logs a warning' do
        expect(Rails.logger).to have_received(:warn).with(state_not_found_message)
      end

      it 'returns the nil' do
        expect(state_method).to eq(nil)
      end
    end

    context 'when state_name is nil' do
      let(:state_name) {}

      it 'returns nil' do
        expect(state_method).to eq(nil)
      end
    end

    context 'when country is nil' do
      let(:country) {}

      it 'returns nil' do
        expect(state_method).to eq(nil)
      end
    end
  end
end

class FakeImportShopWorker
  include Mirakl::ShopPayload

  attr_reader :json_data

  def initialize(json_data)
    @json_data = json_data
  end
end
