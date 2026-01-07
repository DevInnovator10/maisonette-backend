# frozen_string_literal: true

cache_key = [
  I18n.locale,
  line_item,
  line_item.variant,
  line_item.order.completed_at

]

json.cache! cache_key do # rubocop:disable Metrics/BlockLength
  json.call(line_item, *line_item_attributes)
  json.single_display_amount(line_item.single_display_amount.to_s)
  json.display_amount(line_item.display_amount.to_s)
  json.total(line_item.total)
  json.on_sale(line_item.on_sale?)
  json.final_sale(line_item.final_sale?)
  json.original_price(line_item.original_price)
  json.sale_price(line_item.price)
  json.backordered(line_item.backorder_date)
  json.promotionable(line_item.variant.promotionable)

  if line_item.order.completed?
    json.cache! [I18n.locale, 'spree/products/breadcrumbs_taxons', line_item.variant.product_id], expires_in: 3.days do
      json.breadcrumb_taxons do
        json.partial! 'spree/api/taxons/breadcrumb', collection: line_item.product.breadcrumb_taxons, as: :taxon
      end
    end
  end

  json.variant do
    json.partial!('spree/api/variants/small', variant: line_item.variant)
    json.product_id line_item.variant.product_id
    json.master_sku line_item.variant.product.sku
    json.lead_time line_item.variant.lead_time

    json.brand line_item.variant.brand&.name
    json.brand_slug line_item.variant.brand&.permalink_part
    json.brand_description line_item.variant.brand_description
  end

  json.monogram do
    line_item.monogram ? json.partial!('spree/api/monogram/small', monogram: line_item.monogram) : json.nil!
  end

  json.gift_cards(line_item.gift_cards) do |gift_card|
    json.partial!('spree/api/gift_cards/small', gift_card: gift_card)
  end

  json.vendor_name(line_item.vendor.name)
  json.country_iso(line_item.country_iso)
  json.domestic_override(line_item.vendor.domestic_override)

  json.adjustments(line_item.adjustments.promotion.eligible.nonzero) do |adjustment|
    json.partial!('spree/api/adjustments/adjustment', adjustment: adjustment)
  end
end
