# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Invoices::ReSubmitCreditsInvoiceInteractor, mirakl: true do
  describe '#call' do
    let(:resubmit_credits_invoice) { described_class.new mirakl_shop: mirakl_shop }
    let(:mirakl_shop) { instance_double Mirakl::Shop, shop_id: 2002, id: 134, name: 'London Look' }
    let(:mirakl_invoices_for_shop) { class_double Mirakl::Invoice, CREDIT: mirakl_credit_invoices_for_shop }
    let(:mirakl_credit_invoices_for_shop) { class_double Mirakl::Invoice, destroy_all: true }
    let(:shop_credit_invoice_worker) { instance_double Mirakl::ShopCreditsInvoiceWorker, perform: true }

    context 'when it is successful' do
      before do
        allow(Mirakl::Invoice).to(
          receive(:where).with(mirakl_shop: mirakl_shop, issued: false).and_return(mirakl_invoices_for_shop)
        )
        allow(Mirakl::ShopCreditsInvoiceWorker).to receive_messages(new: shop_credit_invoice_worker)

        resubmit_credits_invoice.call
      end

      it 'calls destroy_all on invoices for the mirakl shop' do
        expect(mirakl_credit_invoices_for_shop).to have_received(:destroy_all)
      end

      it 'calls Mirakl::ShopCreditsInvoiceWorker.new.perform with the shop ids' do
        expect(shop_credit_invoice_worker).to have_received(:perform).with(shop_ids: [[mirakl_shop.shop_id,
                                                                                       mirakl_shop.id]])
      end
    end

    context 'when it fails' do
      let(:exception) { StandardError.new('something went wrong') }
      let(:error_message) do
        "#{described_class} Error submitting credits invoice for: #{mirakl_shop.name}"
      end

      before do
        allow(Mirakl::Invoice).to receive(:where).and_raise(exception)
        allow(Sentry).to receive(:capture_exception_with_message)
      end

      it 'fails the interactor' do
        expect { resubmit_credits_invoice.call }.to raise_error(Interactor::Failure)
        expect(Sentry).to have_received(:capture_exception_with_message).with(exception, message: error_message)
      end
    end
  end
end
