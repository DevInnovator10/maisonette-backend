# frozen_string_literal: true

module Spree::Api::OrdersController::StoreCredits
  def self.prepended(base)
    base.admin_order_attributes.push :use_store_credits
    base.after_action :regenerate_proposed_shipments, only: [:update]
  end

  private

  def regenerate_proposed_shipments
    @order.create_proposed_shipments if @order.shipments.empty?
  rescue Spree::Order::InsufficientStock
    message = "skipping, regenerate proposed shipments for order #{@order.number} due to insufficent stock"
    log_event(:info, message)
  end
end
