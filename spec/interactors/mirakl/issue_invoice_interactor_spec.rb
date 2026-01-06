# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::IssueInvoiceInteractor, mirakl: true do
  describe 'hooks' do
    let(:interactor) { described_class.new }

    it 'has before hooks' do
      expect(described_class.before_hooks).to eq [:use_operator_key]
    end
  end

  describe '#call' do
    let(:interactor) { described_class.new(invoice_id: invoice_id) }
    let(:invoice_id) { 'some_invoice_id_1234' }

    before do
      allow(interactor).to receive(:put)

      interactor.call
    end

    it 'calls put /invoices/:invoice_id/issue' do
      expect(interactor).to have_received(:put).with("/invoices/#{invoice_id}/issue")
    end
  end
end
