# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::CreateRecordsCsvWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform('OrderManagement::Entity', records_ids, stream_id) }

    let(:stream_id) { 'timestamp' }
    let(:records_ids) { [1, 2] }
    let(:records) do
      instance_double(ActiveRecord::Relation, first: record, blank?: blank)
    end
    let(:payload) { { 'Name' => 'NameTest' } }
    let(:blank) { false }
    let(:date_time) { instance_double(DateTime) }
    let(:time_stamp) { '12345' }

    let(:s3_directory) do
      "order_management/bulk_data/#{stream_id}/#{record_type}_#{time_stamp}_export.csv"
    end

    before do
      allow(records).to receive(:find_each).and_yield(record)
      allow(DateTime).to receive(:now).and_return(date_time)
      allow(date_time).to receive(:to_i).and_return(time_stamp)
    end

    context 'when record is an order management entity' do
      let(:record) { OrderManagement::Entity.create!(order_manageable: create(:offer_settings)) }
      let(:csv_string) { "\"Name\",\"External_ID__c\"\nNameTest,#{record.external_id}\n" }
      let(:record_type) { 'ordermanagement-test' }

      before do
        allow(record).to receive(:payload).and_return(payload)
        allow(OrderManagement::Entity).to receive(:where).with(id: records_ids).and_return(records)
        allow(S3).to receive(:put).with(s3_directory, csv_string)
      end

      context 'when everything successful' do
        before do
          allow(record).to receive(:type).and_return('OrderManagement::Test')
        end

        it 'create a csv and upload it to S3' do
          expect { perform }.to change(record.reload, :last_request_payload).from({}).to(payload)

          expect(S3).to have_received(:put).with(s3_directory, csv_string)
        end
      end

      context 'when record update error' do
        let(:error) { StandardError.new('failed') }

        before do
          allow(record).to receive(:type).and_return('OrderManagement::Test')
          allow(record).to receive(:update!).and_raise(error)
          allow(Sentry).to receive(:capture_exception_with_message)
        end

        it 'logs the error' do
          expect { perform }.to change(Spree::LogEntry, :count).by(1)

          log_entry = Spree::LogEntry.last

          expect(log_entry.source).to eq record
          expect(log_entry.details).to eq 'failed'
          expect(Sentry).to have_received(:capture_exception_with_message).with(
            error,
            message: "failed Error logged in Spree::LogEntry #{log_entry.id} id"
          )
        end
      end

      context 'when records is blank' do
        let(:blank) { true }

        it 'does nothing' do
          perform

          expect(records).not_to have_received(:find_each)
          expect(S3).not_to have_received(:put)
        end
      end
    end

    context 'when record is not an order management entity' do
      context 'when everything successful' do
        subject(:perform) { described_class.new.perform('Spree::Order', records_ids, stream_id) }

        let(:record) { create(:order) }
        let(:csv_string) { "\"Name\"\nNameTest\n" }
        let(:record_type) { 'spree-order' }

        before do
          allow(record).to receive(:payload_for_oms_csv).and_return(payload)
          allow(Spree::Order).to receive(:where).with(id: records_ids).and_return(records)
          allow(S3).to receive(:put).with(s3_directory, csv_string)
        end

        it 'does not update last_request_payload' do
          perform

          expect(S3).to have_received(:put).with(s3_directory, csv_string)
        end
      end
    end
  end
end
