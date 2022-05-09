# frozen_string_literal: true

module Mirakl
  class ProcessDocumentsWorker
    include Sidekiq::Worker

    MIRAKL_BATCH_SIZE = 100

    def doc_types
      MIRAKL_DATA[:order][:documents].slice(:labels, :package_slip, :customs_form, :system_delivery_bill).values
    end

    def perform(shop_id, orders_with_errors, orders_without_errors, documents_time)
      send_orders_with_no_errors(documents_time, orders_without_errors, shop_id) if orders_without_errors.any?
      send_orders_with_errors(documents_time, orders_with_errors, shop_id) if orders_with_errors.any?
    rescue StandardError => e
      order_ids = orders_with_errors.map { |orders_hash| orders_hash['order_id'] }
      order_ids << orders_without_errors.map { |orders_hash| orders_hash['order_id'] }
      Sentry.capture_exception_with_message(e,
                                            extra: { documents_time: documents_time,
                                                     shop_id: shop_id,
                                                     order_ids: order_ids })
    end

    private

    def send_orders_with_no_errors(documents_time, orders_without_errors, shop_id)
      order_ids = orders_without_errors.map { |order| order['order_id'] }

      groups = (Mirakl::Order.where(id: order_ids).count - 1) / MIRAKL_BATCH_SIZE + 1
      Mirakl::Order.where(id: order_ids).find_in_batches(batch_size: MIRAKL_BATCH_SIZE).with_index do |orders, group|
        batch = [group + 1, groups]
        delivery_args = prepare_documents_for_delivery(shop_id, orders, batch, documents_time)
        Mirakl::SendDocumentsInteractor.call(delivery_args)
      end
    end

    def send_orders_with_errors(documents_time, orders_with_errors, shop_id)
      orders_not_yet_sent = orders_with_errors.reject { |orders| orders['error_sent'] }
      return if orders_not_yet_sent.empty?

      order_ids = orders_not_yet_sent.map { |order| order['order_id'] }

      delivery_args = {
        shop_id: shop_id,
        order_ids: order_ids,
        documents_time: documents_time,
      }
      Mirakl::SendDocumentErrorsInteractor.call(delivery_args)
    end

    def prepare_documents_for_delivery(shop_id, orders, batch, documents_time)
      produce_orders_manifest = produce_orders_manifest(orders)
      response = download_documents(orders)
      archive = process_documents(response, produce_orders_manifest.orders_manifest)
      {
        shop_id: shop_id,
        archive: archive,
        order_ids: orders.pluck(:id),
        total_items_quantity: produce_orders_manifest.total_items_quantity,
        documents_time: documents_time,
        batch: batch
      }
    end

    def download_documents(orders)
      args = { logistic_order_id: orders.pluck(:logistic_order_id).join(','), doc_types: doc_types }
      Mirakl::DownloadOrderDocumentsInteractor.call(args).response ||
        raise('Empty response from download order documents endpoint')
    end

    def process_documents(response, orders_manifest)
      result = Mirakl::ProcessDocumentsInteractor.call(documents: response.body, manifest: orders_manifest)

      raise 'Failed to process documents' if result.failure?

      result.archive
    end

    def produce_orders_manifest(orders)
      ProduceOrdersManifestInteractor.call(orders: orders).tap do |result|
        raise 'Failed to produce orders manifest' if result.failure?
      end
    end
  end
end
