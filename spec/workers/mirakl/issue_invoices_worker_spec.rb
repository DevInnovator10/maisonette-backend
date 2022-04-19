# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::IssueInvoicesWorker, mirakl: true do
  describe 'perform' do
    let(:invoices) { [] }
    let(:invoice1) { instance_double Mirakl::Invoice, update: true, invoice_id: 'invoice_123_id1' }
    let(:invoice2) { instance_double Mirakl::Invoice, update: true, invoice_id: 'invoice_123_id2' }
    let(:issue_invoice1_context) { instance_double Interactor::Context, success?: true }
    let(:slack_channel) { 'vendor-invoices-feed' }
    let(:fees_invoices) { %w[invoice_1 invoice_2] }
    let(:credit_invoices) { %w[invoice_3] }

    before do
      allow(Mirakl::Invoice).to receive_messages(where: invoices)
      allow(Maisonette::Slack).to receive(:notify)
      allow(Maisonette::Config).to receive(:fetch).with('slack.vendor_invoices_feed').and_return(slack_channel)
      allow(Mirakl::Invoice).to receive(:where).with(issued: false, invoice_type: :INVOICE).and_return(fees_invoices)
      allow(Mirakl::Invoice).to receive(:where).with(issued: false, invoice_type: :CREDIT).and_return(credit_invoices)
    end

    it 'calls finds Mirakl::Invoices that are not issued' do
      described_class.new.perform
      expect(Mirakl::Invoice).to have_received(:where).with(issued: false)
    end

    it 'notifies slack' do
      described_class.new.perform
      slack_message = "Successfully issued Mirakl invoices:
Credit: 1
Fees: 2"
      expect(Maisonette::Slack).to have_received(:notify).with(channel: slack_channel,
                                                               username: 'Mirakl Invoices',
                                                               payload: slack_message)
    end

    context 'when the result is successful' do
      let(:invoices) { [invoice1, invoice2] }

      before do
        allow(Mirakl::IssueInvoiceInteractor).to receive(:call).and_return(issue_invoice1_context)

        described_class.new.perform
      end

      it 'calls Mirakl::IssueInvoiceInteractor on all invoices' do
        invoices.each do |invoice|
          expect(Mirakl::IssueInvoiceInteractor).to have_received(:call).with(invoice_id: invoice.invoice_id)
        end
      end

      it 'updates both invoices with issued: true' do
        expect(invoices).to all have_received(:update).with(issued: true)
      end
    end

    context 'when the result is false' do
      let(:invoices) { [invoice1, invoice2] }
      let(:error_message) do
        I18n.t('errors.issue_invoice_worker', class_name: described_class.name, invoice_id: invoice2.invoice_id)
      end
      let(:issue_invoice2_context) { instance_double Interactor::Context, success?: false }

      before do

        allow(Mirakl::IssueInvoiceInteractor).to receive(:call).and_return(issue_invoice1_context,
                                                                           issue_invoice2_context)
        allow(Sentry).to receive(:capture_message)

        described_class.new.perform
      end

      it 'calls Mirakl::IssueInvoiceInteractor on all invoices' do
        invoices.each do |invoice|
          expect(Mirakl::IssueInvoiceInteractor).to have_received(:call).with(invoice_id: invoice.invoice_id)
        end
      end

      it 'updates one invoice with issued: true' do
        expect(invoice1).to have_received(:update).with(issued: true)
      end

      it 'raises a message in Sentry' do
        expect(Sentry).to have_received(:capture_message).with(error_message)
      end
    end
  end
end
