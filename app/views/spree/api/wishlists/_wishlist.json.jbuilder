# frozen_string_literal: true

with_products ||= false

json.call wishlist, :id, :user_id, :name, :is_public, :is_default

if with_products

  json.wished_products do
    json.partial! 'spree/api/wished_products/wished_product', collection: wishlist.wished_products, as: :wished_product
  end
end
