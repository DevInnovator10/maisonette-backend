# frozen_string_literal: true

module Spree::Api::CheckoutsController::EnsurePriceNotStale
  def self.prepended(base)
    base.rescue_from Spree::Order::PriceNotStale::StalePriceError, with: :handle_stale_price
    base.rescue_from Spree::Order::PriceNotStale::StalePaymentError, with: :handle_stale_payment
    base.rescue_from Spree::Order::PriceNotStale::OutOfStockError, with: :handle_out_of_stock_variant
  end

  private

  def handle_stale_price(exception)
    Sentry.capture_exception_with_message(exception)

    @errors = @order.errors.to_hash
    @order.update(state: :payment)

    respond_with @order, default_template: 'spree/api/orders/stale_price_error', status: 422
  end

  def handle_stale_payment(exception)
    Sentry.capture_exception_with_message(exception)

    @errors = @order.errors.to_hash
    @order.update(state: :payment)

    respond_with @order, default_template: 'spree/api/orders/stale_payment_error', status: 422
  end

  def handle_out_of_stock_variant(exception)
    render json: { error: exception.message }, status: 422
  end
end
