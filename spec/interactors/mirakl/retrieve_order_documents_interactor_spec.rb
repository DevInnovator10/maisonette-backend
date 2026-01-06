# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::RetrieveOrderDocumentsInteractor, mirakl: true do
  let(:retrieve_order_documents) { described_class.new(mirakl_orders: [mirakl_order_id_1, mirakl_order_id_2]) }

  describe '#call' do
    let(:mirakl_order_id_1) { '123-A' }
    let(:mirakl_order_id_2) { '321-A' }
    let(:response) { instance_double RestClient::Response }

    before do
      allow(retrieve_order_documents).to receive_messages(get: response)

      retrieve_order_documents.call
    end

    it 'sends a get to /orders/documents and saves response to context' do
      expect(retrieve_order_documents).to(
        have_received(:get).with("/orders/documents?order_ids=#{mirakl_order_id_1},#{mirakl_order_id_2}")
      )

      expect(retrieve_order_documents.context.response).to eq response
    end
  end
end
