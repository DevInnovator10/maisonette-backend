# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::DeleteOrderDocumentInteractor, mirakl: true do
  let(:interactor) { described_class.new doc_id: doc_id }
  let(:doc_id) { '1234' }

  before do
    allow(interactor).to receive(:delete)

    interactor.call
  end

  it 'calls DELETE /orders/documents/:doc_id' do
    expect(interactor).to have_received(:delete).with("/orders/documents/#{doc_id}")
  end
end
