# frozen_string_literal: true

module Spree::InventoryUnit::Giftwrap
  def giftwrappable?
    return false unless shipment.stock_location&.vendor&.giftwrap_service?

    offer_settings = variant.offer_settings_for_vendor(shipment.stock_location&.vendor)

    offer_settings.nil? || offer_settings.giftwrappable?
  end
end
