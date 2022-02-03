# frozen_string_literal: true

json.call(price, :id, :vendor_id, :price, :original_price, :discount_percent, :total_on_hand, :country_iso)
json.final_sale(price.final_sale?)
json.on_sale(price.on_sale?)
