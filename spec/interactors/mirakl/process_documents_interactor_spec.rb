# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessDocumentsInteractor, mirakl: true do
  describe '#call' do
    subject(:interactor_call) { described_class.call(documents: documents, manifest: manifest) }

    let(:documents) { file_fixture('mirakl/sample_order_documents.zip').read }
    let(:manifest) { file_fixture('mirakl/orders_manifest.csv').read }

    context 'with some data' do
      before do
        allow(CombinePDF).to receive(:new).and_call_original
        allow(CombinePDF).to receive(:parse).and_call_original
        allow(Zip::InputStream).to receive(:open).and_call_original
        allow(Zip::OutputStream).to receive(:write_buffer).and_call_original
      end

      it 'extracts the input ZIP, combine the documents and create the output ZIP' do
        interactor_call
        expect(CombinePDF).to have_received(:new).exactly(3).times
        expect(CombinePDF).to have_received(:parse).at_least(:once)
        expect(Zip::InputStream).to have_received(:open).exactly(3).times
        expect(Zip::OutputStream).to have_received(:write_buffer)
        expect(interactor_call.archive).to include('orders_manifest.csv')
      end
    end

    context 'with unsorted data' do
      let(:type) { Mirakl::ProcessDocumentsInteractor::DOCUMENT_TYPES.first }
      let(:zip_entry1) { instance_double(Zip::Entry, name: "#{type}_B") }
      let(:zip_entry2) { instance_double(Zip::Entry, name: "#{type}_A") }
      let(:zip_entry3) { instance_double(Zip::Entry, name: "#{type}_C") }
      let(:zip_input_stream) { instance_double(Zip::InputStream) }

      before do
        allow(Zip::InputStream).to receive(:open).and_yield(zip_input_stream)
        allow(zip_input_stream).to receive(:get_next_entry).and_return(zip_entry1, zip_entry2, zip_entry3, nil)
        allow(zip_input_stream).to receive(:read).and_return('first', 'second', 'third')
      end

      it 'processes the sorted documents' do
        # rubocop:disable RSpec/MessageSpies
        expect(CombinePDF).to receive(:parse).with('second').ordered.and_return([])
        expect(CombinePDF).to receive(:parse).with('first').ordered.and_return([])
        expect(CombinePDF).to receive(:parse).with('third').ordered.and_return([])

        # rubocop:enable RSpec/MessageSpies
        interactor_call
      end
    end
  end
end
