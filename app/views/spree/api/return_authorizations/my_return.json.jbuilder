# frozen_string_literal: true

json.call(@return_authorization, *return_authorization_attributes)
json.state @return_authorization.state

json.reason @return_authorization.reason
json.order @order

json.ship_address { json.partial! 'spree/api/addresses/address', address: @order.ship_address }
json.bill_address { json.partial! 'spree/api/addresses/address', address: @order.bill_address }

json.return_items(@return_authorization.return_items) do |item|
  json.name item.variant.name
  json.brand item.variant.brand
  json.brand_slug item.variant.brand&.navigation_url

  json.image item.variant.product.images&.first&.attachment&.url(:small)
  json.product_slug item.variant.product.slug
  json.cost item.total_excluding_vat

  json.option_values(item.variant.option_values) do |ov|
    json.type ov.option_type.presentation
    json.value ov.presentation
  end

end

json.payments(@order.payments.valid) do |payment|
  json.payment_method { json.call(payment.payment_method, :id, :name) }
  json.partial! 'spree/api/payments/source', payment: payment
end

json.refunded_total @refunded_total

json.fees(@return_authorization.fees) do |fee|
  json.call(fee, :amount, :fee_type)
end

json.cache! [I18n.locale, @order, @return_authorization, @refunded_total] do
  json.partial! 'spree/api/orders/subtotals', order: @order
end
