# frozen_string_literal: true

module Spree::Product::AdvertisedPromotions
  def self.prepended(base)
    base.has_many :products_promotions,
                  class_name: 'Maisonette::ProductsPromotions',
                  foreign_key: :spree_product_id,
                  inverse_of: :product

    base.has_many :advertised_promotions,
                  through: :products_promotions,
                  class_name: 'Spree::Promotion',
                  source: :promotion
  end
end
