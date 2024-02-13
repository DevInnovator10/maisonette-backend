# frozen_string_literal: true

wishlist ||= @wishlist

json.cache! [I18n.locale, wishlist, wishlist.wished_product_ids] do
  json.partial! 'spree/api/wishlists/wishlist', wishlist: wishlist, with_products: true
end
