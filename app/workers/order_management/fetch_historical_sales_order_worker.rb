# frozen_string_literal: true

module OrderManagement
  class FetchHistoricalSalesOrderWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(records_ids)
      orders = Spree::Order.where(id: records_ids)
      return if orders.blank?

      response = OrderManagement::ClientInterface.query_sales_order_by_spree_order_numbers(
        orders.map(&:number)
      )
      return if response.empty?

      orders.each do |order|
        update_sales_order(response, order)
      end
    rescue StandardError => e
      Raven.capture_exception(e, message: e.message)

    end

    private

    def update_sales_order(response, order)
      order_management_ref = response.mapped_orders_ref[order.number]
      return unless order_management_ref

      sales_order = OrderManagement::SalesOrder.find_by!(spree_order_id: order.id)
      sales_order.update!(order_management_ref: order_management_ref)
      OrderManagement::FetchHistoricalOrderItemSummaryWorker.perform_async(
        sales_order.id
      )
    end
  end
end
