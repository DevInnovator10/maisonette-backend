# frozen_string_literal: true

module OrderManagement
  module OrderFinalizedSubscriber
    include Spree::Event::Subscriber

    event_action :send_to_order_management, event_name: :order_finalized

    def send_to_order_management(event)
      order = event.payload[:order]
      if order.send_to_order_management?
        submit_to_order_management(order)
      else
        submit_to_mirakl(order)
      end
    rescue StandardError => e
      log_error(e)
    end

    private

    def submit_to_mirakl(order)
      return if order.shipments.mirakl_shipments.blank?

      Mirakl::SubmitOrderWorker.perform_async(order.number)
    end

    def submit_to_order_management(order)
      create_sales_order(order)
      create_order_summary
      create_order_item_summaries
      OrderManagement::SendSalesOrderWorker.perform_async(@sales_order.id)
    end

    def create_sales_order(spree_order)
      @sales_order = OrderManagement::SalesOrder.find_or_create_by!(spree_order_id: spree_order.id)
    end

    def create_order_summary
      return if @sales_order.order_summary

      @sales_order.create_order_summary!
    end

    def create_order_item_summaries
      ActiveRecord::Base.transaction do
        [*spree_order_line_items, *spree_order_shipments].each do |item|
          @sales_order.order_item_summaries.find_or_create_by!(summarable: item)
        end
      end
    end

    def spree_order_line_items
      @sales_order.spree_order.line_items
    end

    def spree_order_shipments
      @sales_order.spree_order.shipments
    end

    def log_error(exception)
      Rails.logger.error(exception)
      Sentry.capture_exception_with_message(exception)
    end
  end
end
