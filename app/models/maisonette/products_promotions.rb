# frozen_string_literal: true

module Maisonette
  class ProductsPromotions < ApplicationRecord

    self.table_name = 'maisonette_products_promotions'

    belongs_to :product,
               class_name: 'Spree::Product',
               foreign_key: :spree_product_id,
               inverse_of: :products_promotions
    belongs_to :promotion,
               class_name: 'Spree::Promotion',
               foreign_key: :spree_promotion_id,
               inverse_of: :products_promotions
  end
end
