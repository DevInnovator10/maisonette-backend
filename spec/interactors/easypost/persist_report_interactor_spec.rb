# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::PersistReportInteractor do

  describe 'call' do
    subject(:interactor) do
      described_class.call(
        csv_tables: [csv_tables],
        report: report
      )
    end

    let!(:easypost_order) { create(:easypost_order, tracking_code: csv_row['tracking_code']) }
    let(:report) { create(:easypost_report, :shipment_invoice, status: 'available') }
    let(:csv_tables) do
      CSV.parse(file_fixture('easypost/sample_shipment_invoice.csv').read, col_sep: ',', headers: true)
    end
    let(:csv_row) do
      csv_tables.first
    end

    context 'when is a successful' do
      it 'creates a ShippingInvoice record' do
        expect { interactor }.to change(Maisonette::ShippingInvoice, :count).by(1)
        expect(report.status).to eq 'done'
        invoice = Maisonette::ShippingInvoice.last
        expect(invoice.amount).to eq Spree::Money.new(csv_row['quoted_amount']).money.to_f
        expect(invoice.adjustment_amount).to eq Spree::Money.new(csv_row['adjustment_amount']).money.to_f
        expect(invoice.order_number).to eq easypost_order.spree_shipment.order.number
      end

      context 'when ShippingInvoice is present' do
        let!(:invoice) do
          Maisonette::ShippingInvoice.create!(carrier: nil, tracking_code: csv_row['tracking_code'])
        end

        it 'updates the ShippingInvoice' do
          expect { interactor }.to change { invoice.reload.carrier }.from(nil).to(csv_row['carrier'])
        end
      end
    end

    context 'when there is an exception' do
      let(:exception) { StandardError.new }

      before do
        allow(Maisonette::ShippingInvoice).to receive(:find_or_initialize_by).and_raise(exception)
        allow(Sentry).to receive(:capture_exception).with(exception)
      end

      it 'captures the exception' do
        interactor

        expect(Sentry).to have_received(:capture_exception).with(exception)
      end
    end
  end
end
