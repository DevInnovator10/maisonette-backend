# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::ImportShippingInvoicesWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform }

    context 'when invoice_data does not exist' do
      before do
        allow(S3).to receive(:get).and_raise(Aws::S3::Errors::NoSuchKey.new('context', 'message'))
        allow(Sentry).to receive(:capture_exception_with_message)
        allow(CSV).to receive(:parse)
        perform
      end

      it 'notifies Sentry that the invoice data is missing' do
        expect(Sentry).to have_received(:capture_exception_with_message).with(Aws::S3::Errors::NoSuchKey,
                                                                              message: 'No Invoice Data in S3')
      end

      it 'does not try to parse any CSV' do
        expect(CSV).not_to have_received(:parse)
      end
    end

    context 'when there is invoice data' do
      # rubocop:disable Metrics/LineLength
      let(:invoice_data) do
        'amount,weight,weight_unit,order_number,invoice_number,billing_account,tracking_code,carrier,transaction_date,invoice_date
89.06,10,L,order_1,invoice_1,billing_1,tracking_1,carrier_1,2019-09-25,2020-09-25'
      end
      # rubocop:enable Metrics/LineLength

      let(:easypost_order) { Easypost::Order.new(tracking_code: 'tracking_1') }
      let(:shipping_invoice) do
        Maisonette::ShippingInvoice.new(tracking_code: 'tracking_1',
                                        easypost_order_id: easypost_order.id)
      end

      before do
        easypost_order
        shipping_invoice
        allow(S3).to receive_messages(get: invoice_data, delete: true)
        allow(Maisonette::ShippingInvoice).to receive(:find_or_initialize_by).with(tracking_code: 'tracking_1')
                                                                             .and_return(shipping_invoice)
        perform
      end

      it { expect(shipping_invoice.amount).to eq 89.06 }
      it { expect(shipping_invoice.billing_account).to eq 'billing_1' }
      it { expect(shipping_invoice.weight).to eq 10 }
      it { expect(shipping_invoice.weight_unit).to eq 'L' }
      it { expect(shipping_invoice.order_number).to eq 'order_1' }
      it { expect(shipping_invoice.carrier).to eq 'carrier_1' }
      it { expect(shipping_invoice.transaction_date).to eq '2019-09-25 00:00:00.000000000 -0400' }
      it { expect(shipping_invoice.easypost_order_id).to eq easypost_order.id }
      it { expect(shipping_invoice.invoice_date).to eq '2020-09-25 00:00:00.000000000 -0400' }

      it 'calls S3.delete with the patch' do
        expect(S3).to have_received(:delete).with('invoices/invoice_data.csv',
                                                  bucket: Maisonette::Config.fetch('aws.private_bucket'))
      end
    end
  end
end
