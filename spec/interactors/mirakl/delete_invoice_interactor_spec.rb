# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::DeleteInvoiceInteractor, mirakl: true do
  describe 'hooks' do
    let(:interactor) { described_class.new }

    it 'has before hooks' do
      expect(described_class.before_hooks).to eq [:use_operator_key]
    end
  end

  describe '#call' do
    let(:interactor) { described_class.new(invoice_id: invoice_id) }
    let(:invoice_id) { 'invoice-id-123' }

    context 'when it is successful' do
      before do
        allow(interactor).to receive(:delete)

        interactor.call
      end

      it 'sends DELETE to /invoices/:id' do
        expect(interactor).to have_received(:delete).with("/invoices/#{invoice_id}")
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new('something went wrong') }

      before do
        allow(interactor).to receive(:rescue_and_capture)
        allow(interactor).to receive(:delete).and_raise(exception)

        interactor.call
      end

      it 'rescues and captures the exception' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  error_details: "Invoice ID: #{invoice_id}")
        )
      end
    end
  end
end
