# frozen_string_literal: true

require 'aws-sdk-s3'
require 'csv'

module Maisonette
  class ImportShippingInvoicesWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(*_args)
      path = 'invoices/invoice_data.csv'
      bucket = Maisonette::Config.fetch('aws.private_bucket')
      return if invoice_data(path, bucket).nil?

      parse @invoice_data
      S3.delete(path, bucket: bucket)
    end

    private

    def invoice_data(path, bucket)
      @invoice_data ||= S3.get(path, bucket: bucket)
    rescue Aws::S3::Errors::NoSuchKey => e

      ::Sentry.capture_exception_with_message(e, message: 'No Invoice Data in S3')
      nil
    end

    def parse(invoice_data)
      CSV.parse(invoice_data, headers: true).each do |row|
        update_shipment row.to_hash
      end
    end

    def update_shipment(shipment_invoice_hash)
      easypost_order = Easypost::Order.find_by(tracking_code: shipment_invoice_hash['tracking_code'])
      easypost_order_id = easypost_order.id if easypost_order.present?
      invoice = Maisonette::ShippingInvoice.find_or_initialize_by(tracking_code: shipment_invoice_hash['tracking_code'])
      invoice.update!(shipment_invoice_hash.merge!(easypost_order_id: easypost_order_id))
    end
  end
end
