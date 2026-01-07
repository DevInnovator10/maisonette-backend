# frozen_string_literal: true

module OrderManagement
  class CreateHistoricalSalesOrderWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(order_ids)
      order_ids.each do |id|
        sales_order = OrderManagement::SalesOrder.find_or_create_by!(spree_order_id: id)
        sales_order.spree_order.line_items.each do |li|
          sales_order.order_item_summaries.find_or_create_by!(summarable: li, sales_order_id: sales_order.id)
        end
      end
    end
  end
end
