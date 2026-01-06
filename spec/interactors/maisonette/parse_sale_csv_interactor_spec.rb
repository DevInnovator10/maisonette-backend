# frozen_string_literal: true

require 'rails_helper'
require 'roo'

RSpec.describe Maisonette::ParseSaleCsvInteractor do
  describe '#call' do
    subject(:interactor) { described_class.call(interactor_context) }

    let(:sale) { create(:sale) }
    let(:interactor_context) { { sale_id: sale.id, file_path: file_path } }
    let(:vendor1) { create(:vendor, name: 'Vendor1') }
    let(:product3) { create(:product, name: 'Product, 3') }

    context 'when the file is a CSV' do
      let(:file_path) { File.join(Rails.root, 'spec/fixtures/files/maisonette_sale/search.csv').to_s }

      it 'returns the correct collection of offer settings' do
        offer_settings1 = create :offer_settings, vendor: vendor1, maisonette_sku: 'ms-001'
        offer_settings2 = create :offer_settings, vendor_sku: 'vs-002'
        offer_settings3 = create :offer_settings, variant: product3.master, maisonette_sku: 'ms-003'
        create :offer_settings

        context = interactor

        expect(context.collection).to match([offer_settings1, offer_settings2, offer_settings3])
      end

      it 'returns an error if file is malformed' do
        allow(CSV).to receive(:foreach).and_raise(CSV::MalformedCSVError.new('error', 1))

        context = interactor

        expect(context.message).to eq('error in line 1.')
      end
    end

    context 'when the file is a XLSX' do
      let(:file_path) { File.join(Rails.root, 'spec/fixtures/files/maisonette_sale/search.xlsx').to_s }

      it 'returns the correct collection of offer settings' do
        offer_settings1 = create :offer_settings, vendor: vendor1, maisonette_sku: 'ms-001'
        offer_settings2 = create :offer_settings, vendor_sku: 'vs-002'
        offer_settings3 = create :offer_settings, variant: product3.master, maisonette_sku: 'ms-003'
        create :offer_settings

        context = interactor

        expect(context.collection).to match([offer_settings1, offer_settings2, offer_settings3])
      end

      it 'returns an error if file is malformed' do
        allow(Roo::Spreadsheet).to receive(:open).and_raise(Zip::Error.new('error'))

        context = interactor

        expect(context.message).to eq('error')
      end

      it 'returns an error if header is wrong' do
        exception = Roo::HeaderRowNotFoundError.new(['Product Name', 'Maisonette SKU'])
        allow(Roo::Spreadsheet).to receive(:open).and_raise(exception)

        context = interactor

        expect(context.message).to eq('missing headers ["Product Name", "Maisonette SKU"]')
      end
    end

    context 'when file is empty' do
      let(:file_path) { File.join(Rails.root, 'spec/fixtures/files/maisonette_sale/empty.csv').to_s }

      it 'returns a file empty error' do
        context = interactor

        expect(context.message).to eq('The file is empty')
      end
    end
  end
end
