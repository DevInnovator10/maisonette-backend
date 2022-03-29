# frozen_string_literal: true

require 'csv'

module OrderManagement
  class CreateRecordsCsvWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(model, records_ids, stream_id)
      records = model.constantize.where(id: records_ids)
      return if records.blank?

      record = records.first

      record_type = record_type_name(record)
      create_csv_rows(records)
      upload_csv(stream_id, record_type) if @csv_data
    rescue StandardError => e
      Sentry.capture_exception_with_message(e, message: e.message)
    end

    private

    def record_type_name(record)
      if record.respond_to?(:type)
        record.type.parameterize
      else
        record.class.name.parameterize
      end
    end

    def record_error_message(log)
      "Error logged in Spree::LogEntry #{log.id} id"
    end

    def create_csv_rows(records)
      records.find_each do |record|
        payload = record.payload_for_oms_csv
        generate_csv_with_headers(headers(record, payload)) unless @csv_data
        @csv_data << order_line_row(payload, record)
        record.update!(last_request_payload: payload) if record.respond_to?(:last_request_payload)
      rescue StandardError => e
        log = Spree::LogEntry.create(source: record, details: e.message)
        Sentry.capture_exception_with_message(e, message: "#{e.message} #{record_error_message(log)}")
      end
    end

    def generate_csv_with_headers(headers)
      @csv_data = CSV.generate_line(headers, force_quotes: true)
    end

    def order_line_row(payload, record)
      if record.respond_to?(:external_id)
        CSV.generate_line(payload.values + [record.external_id])
      else
        CSV.generate_line(payload.values)
      end
    end

    def headers(record, payload)
      if record.respond_to?(:external_id)
        payload.transform_keys(&:to_s).keys + ['External_ID__c']
      else
        payload.transform_keys(&:to_s).keys
      end
    end

    def upload_csv(stream_id, record_type)
      S3.put(object_path(stream_id, record_type), @csv_data)
    end

    def object_path(stream_id, record_type)
      "#{directory(stream_id)}/#{record_type}_#{DateTime.now.to_i}_export.csv"
    end

    def directory(stream_id)
      "order_management/bulk_data/#{stream_id}"
    end
  end
end
