# frozen_string_literal: true

module Spree::Admin::PaymentsController::RescueOutOfStockError
  def self.prepended(base)
    base.rescue_from Spree::Order::PriceNotStale::OutOfStockError, with: :handle_out_of_stock_variant
  end

  private

  def handle_out_of_stock_variant(exception)
    flash[:error] = exception.message

    redirect_to edit_admin_order_url(@order)
  end
end
