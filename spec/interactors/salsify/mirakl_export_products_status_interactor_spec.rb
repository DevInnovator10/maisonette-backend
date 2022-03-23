# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::MiraklExportProductsStatusInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) { described_class.new(unsynced_products: unsynced_products, synchro_id: synchro_id) }
    let(:synchro_id) { '1111' }
    let(:mirakl_product_export_job) { instance_double Salsify::MiraklProductExportJob, updated_in_salsify!: true }

    before do
      allow(Salsify::MiraklProductExportJob).to(
        receive(:find_by)
          .with(synchro_id: synchro_id)
          .and_return(mirakl_product_export_job)
      )
    end

    context 'when Salsify receives the payload for update: response code 204' do
      let(:error_message_1) { 'error 1' }
      let(:error_message_2) { 'error 3' }
      let(:unsynced_products) do
        [{ 'product-id' => '0011', 'error-message' => error_message_1 },
         { 'product-id' => '0033', 'error-message' => error_message_2 }]
      end
      let(:all_products_ids) { %w[0011 0022 0033] }
      let(:payload) do
        [{ 'id': '0022',
           'Mirakl Export Property': 'EXPORTED',
           'Mirakl Export Error Message': nil },
         { 'id': '0011',
           'Mirakl Export Property': 'EXPORT_FAILED',
           'Mirakl Export Error Message': 'error 1' },
         { 'id': '0033',
           'Mirakl Export Property': 'EXPORT_FAILED',
           'Mirakl Export Error Message': 'error 3' }]
      end

      before do
        allow(interactor).to receive_messages(put: instance_double(RestClient::Response, code: 204),
                                              all_products_ids: all_products_ids)

        interactor.call
      end

      it 'calls /products with a payload of errors' do
        expect(interactor).to have_received(:put).with('/products', payload: payload.to_json)
      end

      it 'sets MiraklProductExportJob status as updated_in_salsify' do
        expect(mirakl_product_export_job).to have_received(:updated_in_salsify!)
      end

      context 'when the encoding of error is not utf-8' do
        let(:error_message_1) { (+"D\xC3\xA9cor").force_encoding('ASCII-8BIT') }

        it 'calls /products with a payload of errors' do
          expect(interactor).to have_received(:put).with(
            '/products',
            payload: match('Mirakl Export Error Message":"D\xC3\xA9cor"')
          )
        end
      end

      context 'when the encoding of error is utf-8' do
        let(:error_message_1) { (+"D\xC3\xA9cor").force_encoding('utf-8') }

        it 'calls /products with a payload of errors' do
          expect(interactor).to have_received(:put).with(
            '/products',
            payload: match('Mirakl Export Error Message":"D\xC3\xA9cor"')
          )
        end
      end

      context 'when the error message not a string' do
        let(:error_message_1) { 3 }

        it 'calls /products with a payload of errors' do
          expect(interactor).to have_received(:put).with(
            '/products',
            payload: match('Mirakl Export Error Message":3')
          )
        end
      end
    end

    context 'when Salsify does not receive the payload for update for any reason' do
      let(:unsynced_products) { ['some_product'] }
      let(:mirakl_product_export_job) do
        instance_double(Salsify::MiraklProductExportJob, synchro_id: synchro_id, status: :sent, error_in_salsify!: true)
      end

      context 'when the response code is not 204' do
        before do
          allow(interactor).to receive_messages(put: instance_double(RestClient::Response, code: 404),
                                                all_products_ids: [])

          interactor.call
        end

        it 'sets MiraklProductExportJob status as error_in_salsify' do
          expect(mirakl_product_export_job).to have_received(:error_in_salsify!)
        end
      end

      context 'when the response is false' do
        before do
          allow(interactor).to receive_messages(put: false,
                                                all_products_ids: [])

          interactor.call
        end

        it 'sets MiraklProductExportJob status as error_in_salsify' do
          expect(mirakl_product_export_job).to have_received(:error_in_salsify!)
        end
      end
    end
  end

  describe '#all_products_ids' do
    subject(:all_products_ids) { interactor.send(:all_products_ids) }

    let(:interactor) { described_class.new }
    let(:mirakl_product_export_job) do
      instance_double Salsify::MiraklProductExportJob, read_products_file: product_file
    end
    let(:product_file) { File.read(Rails.root.join('spec', 'fixtures', 'salsify', 'mirakl', product_file_name)) }
    let(:product_file_name) { 'anything_mirakl_product_feed_maisonette_anything.csv' }

    before do
      allow(interactor).to receive_messages(mirakl_product_export_job: mirakl_product_export_job)
    end

    it 'returns a list of the product ids from the product file' do
      expect(all_products_ids).to match_array(%w[bunnies-small
                                                 bunnies-large
                                                 miniature-start-up
                                                 bunnies-irregular
                                                 bunnies-irregular-monogram])
    end
  end
end
