# frozen_string_literal: true

module Spree::ShippingMethod::ShippingCarrier
  def self.prepended(base)
    base.has_many :shipping_method_carriers, dependent: :destroy
    base.has_many :shipping_carriers, through: :shipping_method_carriers
  end
end
