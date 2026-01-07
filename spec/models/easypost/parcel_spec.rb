# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::Parcel, mirakl: true do
  it_behaves_like 'an Easypost active record model'

  describe 'relations' do
    it { is_expected.to have_many(:easypost_shipments).inverse_of(:easypost_parcel).class_name('Easypost::Shipment') }
    it { is_expected.to have_many(:easypost_orders).class_name('Easypost::Order').through(:easypost_shipments) }
  end

  describe 'create_easypost_parcel' do
    let(:easypost_parcel) { build_stubbed :easypost_parcel }
    let(:easy_post_parcel_object) { instance_double EasyPost::Parcel, id: 'P123' }
    let(:easypost_dimensions) { { width: 5, length: 10, height: 12.2, weight: 5.5 } }

    before do
      allow(EasyPost::Parcel).to receive_messages(create: easy_post_parcel_object)
      allow(easypost_parcel).to receive_messages(easypost_dimensions: easypost_dimensions)
    end

    context 'when a api key is not passed' do
      before { easypost_parcel.create_easypost_parcel }

      it 'calls EasyPost::Parcel.create with the default easypost_api_key' do
        expect(EasyPost::Parcel).to have_received(:create).with(easypost_dimensions,
                                                                Rails.application.secrets.easypost_api_key)
      end

      it 'assigns easypost_id' do
        expect(easypost_parcel.easypost_id).to eq easy_post_parcel_object.id
      end
    end

    context 'when a api key is passed' do
      let(:easypost_api_key) { 'api1234' }

      before { easypost_parcel.create_easypost_parcel(easypost_api_key: easypost_api_key) }

      it 'calls EasyPost::Parcel.create with the passed easypost_api_key' do
        expect(EasyPost::Parcel).to have_received(:create).with(easypost_dimensions, easypost_api_key)
      end

      it 'assigns easypost_id' do
        expect(easypost_parcel.easypost_id).to eq easy_post_parcel_object.id
      end
    end
  end

  describe 'dimensions' do
    let(:easypost_parcel) { build_stubbed :easypost_parcel, width: 5.5, length: 2.5, height: nil, weight: 1.2 }

    it 'returns parcel dimensions as a hash' do
      expect(easypost_parcel.dimensions).to eq(width: 5.5, length: 2.5, height: 0.0, weight: 1.2)
    end
  end

  describe 'easypost_dimensions' do
    let(:easypost_parcel) { build_stubbed :easypost_parcel, width: 5.5, length: 2.5, height: nil, weight: 1.2 }
    let(:weight_in_ounces) { Measured::Weight(1.2, :lbs).convert_to(:oz).value.to_f }

    it 'returns parcel easypost dimensions as a hash' do
      expect(easypost_parcel.easypost_dimensions).to eq(width: 5.5, length: 2.5, height: 0.0, weight: weight_in_ounces)
    end

    context 'with empty weight' do
      let(:easypost_parcel) { build_stubbed :easypost_parcel, width: 5.5, length: 2.5, height: nil, weight: nil }

      it 'returns parcel easypost dimensions as a hash' do
        expect(easypost_parcel.easypost_dimensions).to eq(width: 5.5, length: 2.5, height: 0.0, weight: 0)
      end
    end
  end
end
