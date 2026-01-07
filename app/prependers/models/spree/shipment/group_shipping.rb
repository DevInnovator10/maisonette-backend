# frozen_string_literal: true

module Spree::Shipment::GroupShipping
  def select_shipping_method(shipping_method)
    super

    order.reload.apply_shipping_promotions
  end

  def selected_shipping_rate_id=(id)
    super

    order.reload.apply_shipping_promotions
  end
end
