# frozen_string_literal: true

json.partial!('spree/api/orders/order', order: order)
json.partial!('spree/api/orders/narvar', order: order)

json.free_shipping_threshold Maisonette::Config.free_shipping_threshold

json.payment_methods(order.available_payment_methods) do |payment_method|
  json.call(payment_method, :id, :name)
end

json.bill_address do
  if order.billing_address
    json.partial!('spree/api/addresses/address', address: order.billing_address)
  else
    json.nil!
  end
end

json.ship_address do
  if order.shipping_address
    json.partial!('spree/api/addresses/address', address: order.shipping_address)
  else
    json.nil!
  end
end

json.line_items(order.line_items) do |line_item|
  json.partial!('spree/api/line_items/line_item', line_item: line_item)
end

json.payments(order.payments) do |payment|
  json.call(payment, *payment_attributes)
  json.payment_method { json.call(payment.payment_method, :id, :name) }
  json.partial! 'spree/api/payments/source', payment: payment
end

json.shipments(order.shipments.order(:created_at)) do |shipment|
  json.partial!('spree/api/shipments/small', shipment: shipment)
  json.stock_location_address shipment.stock_location.address
  json.country_iso shipment.stock_location.country_iso
  json.international_shipping shipment.stock_location.international?
  json.delivery_estimation(shipment.easypost_delivery_estimation || shipment.delivery_estimation)
  json.estimated_giftwrap_price shipment.estimated_giftwrap_price&.to_d
  json.display_estimated_giftwrap_price shipment.display_estimated_giftwrap_price
end

json.adjustments(order.adjustments) do |adjustment|
  json.partial!('spree/api/adjustments/adjustment', adjustment: adjustment)
end

json.permissions do
  json.can_update current_ability.can?(:update, order)
end

json.gift_card_total order.gift_card_total
json.applied_promotion_codes(order.applied_promotion_codes) do |code|
  json.id code.id
  json.promotion_id code.promotion_id
  json.value code.value
  json.expires_at code.expires_at
end

json.partial! 'spree/api/orders/subtotals', order: order

json.partial!('spree/api/orders/address_verification', address_verification: order.address_verification)
