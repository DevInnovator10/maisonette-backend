# frozen_string_literal: true

module Spree::Store::EnabledShippingServiceLevels
  def self.prepended(base)
    base.serialize :enabled_shipping_service_levels, Array
  end
end
