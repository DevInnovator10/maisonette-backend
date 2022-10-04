# frozen_string_literal: true

module Spree::Api::CheckoutsController::EnsureShippingMethods
  def self.prepended(base)
    base.rescue_from(
      Spree::Order::EnsureShippingMethods::NoShippingMethodError,
      with: :handle_no_shipping_method
    )
  end

  private

  def handle_no_shipping_method(exception)
    render json: { error: exception.message }, status: :unprocessable_entity
  end
end
