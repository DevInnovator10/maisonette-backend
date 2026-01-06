# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::CreateReportWorker do
  subject(:perform) { described_class.new.perform('ShipmentInvoiceReport') }

  describe '#perform' do
    before do
      allow(Easypost::CreateReportOrganizer).to receive(:call).with(
        report_type: 'ShipmentInvoiceReport',
        start_date: Time.zone.yesterday.to_formatted_s(:db),
        end_date: Time.zone.today.to_formatted_s(:db)
      )
    end

    context 'when there is not easypost report' do
      it 'calls CreateReportOrganizer with yesterday date' do
        perform

        expect(Easypost::CreateReportOrganizer).to have_received(:call).with(
          report_type: 'ShipmentInvoiceReport',
          start_date: Time.zone.yesterday.to_formatted_s(:db),
          end_date: Time.zone.today.to_formatted_s(:db)
        )
      end
    end

    context 'when there is a 2 days old easypost report' do
      let!(:easypost_report) do
        create(:easypost_report,
               :shipment_invoice,
               end_date: (Time.zone.today - 2.days).to_formatted_s(:db),
               status: 'done')
      end

      it 'calls CreateReportOrganizer with yesterday date' do
        perform

        expect(Easypost::CreateReportOrganizer).to have_received(:call).with(
          report_type: 'ShipmentInvoiceReport',
          start_date: (easypost_report.end_date + 1.day).to_formatted_s(:db),
          end_date: Time.zone.today.to_formatted_s(:db)
        )
      end
    end
  end
end
