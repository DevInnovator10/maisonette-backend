# frozen_string_literal: true

module Spree
  class ShippingMethodCarrier < Spree::Base
    belongs_to :shipping_method, class_name: 'Spree::ShippingMethod', optional: false
    belongs_to :shipping_carrier,
               class_name: 'Spree::ShippingCarrier',
               inverse_of: :shipping_method_carriers,
               optional: false
  end
end
