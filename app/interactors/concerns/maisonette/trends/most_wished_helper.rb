# frozen_string_literal: true

module Maisonette
  module Trends
    module MostWishedHelper
      include TrendsHelper

      private

      def update_most_wished_trend(taxon_name:, limit: nil)
        taxon = child_trend_taxon(taxon_name)

        products = query_products(limit)
        products_with_vga = query_products_with_vga(limit)

        taxon.repopulate(products, products_with_vga)
      end

      def query_products(limit)
        Spree::Product.joins(variants_including_master: [:wished_products])
                      .where(maisonette_variant_group_attributes: { id: nil })
                      .purchasable
                      .group(:id)
                      .order(count: :desc)
                      .limit(limit)
                      .ids
      end

      def query_products_with_vga(limit)
        Maisonette::VariantGroupAttributes.purchasable
                                          .joins(variants: [:wished_products])
                                          .group(:id)
                                          .order(count: :desc)
                                          .limit(limit)
                                          .pluck(:id, :product_id)
      end
    end
  end
end
