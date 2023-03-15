# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Invoices::BaseInteractor, mirakl: true do
  let(:described_class) { FakeInvoiceInteractor }

  describe '#call' do
    subject(:call) { interactor.call }

    let(:interactor) { described_class.new(mirakl_shop_id: mirakl_shop_id, doc_groups: doc_groups, response: response) }
    let(:mirakl_orders) { class_double Mirakl::Order, update_all: true }
    let(:mirakl_shop_id) { 2002 }
    let(:doc_groups) { { doc_1: ['invoice_line'] } }
    let(:response) {}

    context 'when it is successful' do
      before do
        allow(interactor).to receive_messages(fetch_doc_groups: true,
                                              submit_to_mirakl: true,
                                              create_mirakl_invoice_records: true,
                                              mirakl_orders: mirakl_orders)

        call
      end

      it 'calls fetch_doc_groups' do
        expect(interactor).to have_received(:fetch_doc_groups)
      end

      it 'calls submit_to_mirakl' do
        expect(interactor).to have_received(:submit_to_mirakl)
      end

      it 'calls create_mirakl_invoice_records' do
        expect(interactor).to have_received(:create_mirakl_invoice_records)
      end

      it 'updates all mirakl_orders with invoiced: true' do
        expect(mirakl_orders).to have_received(:update_all).with(invoiced: true)
      end

      context 'when doc_groups is empty' do
        let(:doc_groups) { {} }

        it 'does not call submit_to_mirakl' do
          expect(interactor).not_to have_received(:submit_to_mirakl)
        end

        it 'does not call create_mirakl_invoice_records' do
          expect(interactor).not_to have_received(:create_mirakl_invoice_records)
        end

        it 'updates all mirakl_orders with invoiced: true' do
          expect(mirakl_orders).to have_received(:update_all).with(invoiced: true)
        end
      end
    end

    context 'when an error is thrown' do
      let(:exception) { StandardError.new('something went wrong') }
      let(:error_message) do
        I18n.t('errors.mirakl_shop_invoice_worker',
               class_name: described_class.name,
               invoice_type: :INVOICE,
               shop_id: mirakl_shop_id,
               response: response)
      end
      let(:response) do
        { 'manual_accounting_document_returns' => 'some_error' }.to_json
      end

      before do
        allow(interactor).to receive(:fetch_doc_groups).and_raise(exception)
        allow(Sentry).to receive(:capture_exception_with_message)

        call
      end

      it 'raises an exception in Sentry' do
        expect(Sentry).to have_received(:capture_exception_with_message).with(exception, message: error_message)
      end
    end
  end

  describe '#fetch_doc_groups' do
    subject(:fetch_doc_groups) { interactor.send :fetch_doc_groups }

    let(:interactor) { described_class.new }
    let(:lines) do
      [
        { mirakl_order: 'M001', invoice_line: 'M001 - late shipping fee' },
        { mirakl_order: 'M001', invoice_line: 'M001 - cancellation fee' },
        { mirakl_order: 'M002', invoice_line: 'M002 - late shipping fee' },
        { mirakl_order: 'M002', invoice_line: 'M002 - cancellation fee' },
        { mirakl_order: 'M003', invoice_line: 'M003 - late shipping_fee' },
      ]
    end

    before do
      MIRAKL_DATA[:invoice][:max_lines] = 3
      allow(interactor).to receive_messages(lines: lines)
    end

    it 'returns lines' do
      expect(fetch_doc_groups).to eq 'doc_1' => ['M001 - late shipping fee',
                                                 'M001 - cancellation fee'],
                                     'doc_2' => ['M002 - late shipping fee',
                                                 'M002 - cancellation fee',
                                                 'M003 - late shipping_fee']
    end

    context 'when there are no lines' do
      let(:lines) { [] }

      it 'returns an empty hash' do
        expect(fetch_doc_groups).to eq({})
      end
    end
  end

  describe '#submit_to_mirakl' do
    subject(:submit_to_mirakl) { interactor.send :submit_to_mirakl }

    let(:interactor) do
      described_class.new(mirakl_shop_id: mirakl_shop_id,
                          shop_id: shop_db_id,
                          doc_groups: doc_groups)
    end
    let(:mirakl_shop_id) { 2002 }
    let(:shop_db_id) { 2 }
    let(:doc_groups) do
      { 'doc_1' => ['M001 - late shipping fee',
                    'M001 - cancellation fee'],
        'doc_2' => ['M002 - late shipping fee',
                    'M002 - cancellation fee',
                    'M003 - late shipping_fee'] }
    end
    let(:payload) do
      { manual_accounting_documents:
          [{ issued: false,
             lines: ['M001 - late shipping fee',
                     'M001 - cancellation fee'],
             shop_id: mirakl_shop_id,
             type: 'INVOICE' },
           { issued: false,
             lines: ['M002 - late shipping fee',
                     'M002 - cancellation fee',
                     'M003 - late shipping_fee'],
             shop_id: mirakl_shop_id,
             type: 'INVOICE' }] }
    end
    let(:post_response) { 'response from mirakl' }

    before do
      allow(interactor).to receive_messages(post: post_response)

      submit_to_mirakl
    end

    it 'sends a POST to /invoices with fee invoice lines' do
      expect(interactor).to(have_received(:post).with('/invoices', payload: payload.to_json))
    end

    it 'adds the response to context' do
      expect(interactor.context.response).to eq post_response
    end
  end

  describe '#create_mirakl_invoice_records' do
    subject(:create_mirakl_invoice_records) { interactor.send :create_mirakl_invoice_records }

    let(:interactor) { described_class.new(response: response, shop_id: shop_id) }
    let(:response) do
      { manual_accounting_document_returns: [
        { manual_accounting_document: { id: 'inv_1' } },
        { manual_accounting_document: { id: 'inv_2' } },
      ] }.to_json
    end
    let(:shop_id) { 20 }

    before do
      allow(Mirakl::Invoice).to receive(:create)

      create_mirakl_invoice_records
    end

    it 'creates a mirakl invoice record per document' do
      expect(Mirakl::Invoice).to have_received(:create).with(invoice_id: 'inv_1',
                                                             mirakl_shop_id: shop_id,
                                                             doc_number: 1,
                                                             invoice_type: :INVOICE)
      expect(Mirakl::Invoice).to have_received(:create).with(invoice_id: 'inv_2',
                                                             mirakl_shop_id: shop_id,
                                                             doc_number: 2,
                                                             invoice_type: :INVOICE)
    end
  end
end

class FakeInvoiceInteractor < Mirakl::Invoices::BaseInteractor
  helper_methods :mirakl_orders, :response, :shop_id, :mirakl_shop_id, :doc_groups

  private

  def invoice_type
    :INVOICE
  end

  def lines; end
end
