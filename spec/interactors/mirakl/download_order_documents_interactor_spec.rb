# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::DownloadOrderDocumentsInteractor, mirakl: true do
  let(:download_order_documents) { described_class.new(logistic_order_id: logistic_order_id, doc_types: doc_types) }

  describe '#call' do
    let(:logistic_order_id) { '1234-A' }
    let(:doc_types) { %w[doc_type1 doc_type2] }
    let(:url_params) { '?order_ids=1234-A&document_codes=doc_type1,doc_type2' }
    let(:response) { instance_double RestClient::Response }

    before do
      allow(download_order_documents).to receive_messages(get: response)

      download_order_documents.call
    end

    it 'sends a get to /orders/documents/download and saves response to context' do
      expect(download_order_documents).to have_received(:get).with("/orders/documents/download#{url_params}")
      expect(download_order_documents.context.response).to eq response
    end
  end
end
