# frozen_string_literal: true

module Spree::Admin::OrdersController::EnsurePriceNotStale
  def self.prepended(base)
    base.rescue_from Spree::Order::PriceNotStale::StalePriceError, with: :handle_stale_payment
    base.rescue_from Spree::Order::PriceNotStale::StalePaymentError, with: :handle_stale_payment
  end

  private

  def handle_stale_payment
    flash[:error] = @order.errors.to_hash

    @order.update(state: :payment)
    redirect_to admin_order_payments_url(@order)
  end
end
