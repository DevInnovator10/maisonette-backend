# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::DeleteProductsInteractor, mirakl: true do
    describe '#call' do
    let(:interactor) { described_class.call(products_file: products_file) }
    let(:products_file) { File.new(Rails.root.join('spec', 'fixtures', 'files', 'mirakl', file_name)) }

    context 'when the file is valid' do
      let(:file_name) { 'valid_delete_products.csv' }
      # rubocop:disable RSpec/VerifiedDoubles
      let(:context) { double(Interactor::Context, synchro_id: 'SYNCHRO123') }
      # rubocop:enable RSpec/VerifiedDoubles

      it 'add update-delete column to file', freeze_time: true do
        allow(Mirakl::BinaryFileStringIO).to receive(:new).and_call_original
        allow(Mirakl::ExportProductsInteractor).to receive(:call!).and_return(context)
        csv_content = "product-sku;update-delete\nSKU123;delete\n"

        interactor

        expect(Mirakl::BinaryFileStringIO).to have_received(:new).with(
          csv_content,
          "maisonette_manual_products_delete_#{DateTime.now.to_i}.csv"
        )
      end

      it 'returns the synchro id' do
        allow(Mirakl::ExportProductsInteractor).to receive(:call!).and_return(context)
        expect(interactor.synchro_id).to eq('SYNCHRO123')
      end
    end

    context 'when the file has incorrect headers' do
      let(:file_name) { 'wrong_headers_delete_products.csv' }

      it 'returns an error message' do
        expect(interactor.message).to eq('File must have a single product-sku column')
      end
    end

    context 'when the file has empty rows' do
      let(:file_name) { 'empty_delete_products.csv' }

      it 'returns an error message' do
        expect(interactor.message).to eq('The uploaded file is empty')
      end
    end

    context 'when the export fails' do
      let(:file_name) { 'valid_delete_products.csv' }

      it 'captures and returns the error message' do
        exception = StandardError.new('failure')
        allow(Sentry).to receive(:capture_exception_with_message)
        allow(Mirakl::ExportProductsInteractor).to receive(:call!).and_raise(exception)

        expect(interactor.message).to eq('failure')
        expect(Sentry).to have_received(:capture_exception_with_message).with(exception)
      end
    end
  end
end
