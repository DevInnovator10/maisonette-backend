# frozen_string_literal: true

module Spree::Admin::OrdersController::InsufficientStock
  private

  def insufficient_stock_error
    flash[:error] = line_item_errors.join
    redirect_to edit_admin_order_customer_url(@order)
  end

  def line_item_errors
    line_items.map(&:errors).flat_map(&:full_messages)
  end

  def line_items
    @order.line_items
  end
end
