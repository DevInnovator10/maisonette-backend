# frozen_string_literal: true

module Spree::Admin::ShippingMethodsController::ShippingCarrier
  def self.prepended(base)
    base.before_action :set_shipping_carrier, only: %i[create update]
  end

  def set_shipping_carrier
    return true if params['shipping_method'][:shipping_carriers] == ''

    shipping_carriers = Spree::ShippingCarrier.where(id: params['shipping_method'][:shipping_carriers])
    @shipping_method.shipping_carriers = shipping_carriers
    params[:shipping_method].delete(:shipping_carriers)
  end
end
