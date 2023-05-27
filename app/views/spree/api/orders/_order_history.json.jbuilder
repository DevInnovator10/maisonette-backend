# frozen_string_literal: true

json.cache! [I18n.locale, order] do
  json.number         order.number
  json.completed_at   order.completed_at
  json.total          order.total
  json.state          I18n.t("spree.order_state.#{order.state}").titleize
  json.shipment_state order.shipment_state
  json.shipments(order.shipments.order(:created_at)) do |shipment|
    json.number       shipment.number
    json.state        shipment.state
    json.tracking     shipment.tracking
    json.tracking_url shipment.tracking_url
    json.delivery_estimation(shipment.easypost_delivery_estimation || shipment.delivery_estimation)
  end
end

json.partial!('spree/api/orders/narvar', order: order)
