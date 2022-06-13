# frozen_string_literal: true

module Mirakl
  class CheckShipmentSubmissionWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(*_args) # rubocop:disable Metrics/MethodLength
      yesterday = Time.current.yesterday
      date_range = (yesterday.beginning_of_day..yesterday.end_of_day)
      shipments_missing_mirakl_orders = Spree::Shipment.joins(:order)
                                                       .left_joins(:mirakl_order)
                                                       .mirakl_shipments
                                                       .where(spree_orders: { completed_at: date_range },
                                                              mirakl_orders: { shipment_id: nil })
                                                       .order('spree_orders.number, spree_shipments.number')
      return if shipments_missing_mirakl_orders.blank?

      orders_and_shipments = Hash.new { |hash, key| hash[key] = [] }
      shipments_missing_mirakl_orders.each_with_object(orders_and_shipments) do |shipment, object|
        object[shipment.order.number] << shipment.number
      end
      Sentry.capture_message("Orders and Shipments with missing Mirakl Orders: #{orders_and_shipments}",
                             tags: { notify: :order_sync_issues })
    end
  end
end
