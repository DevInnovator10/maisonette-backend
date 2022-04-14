# frozen_string_literal: true

module Maisonette
  module Trends
    module JustInHelper
      include TrendsHelper

      private

      def update_just_in_trend(taxon_name:, date:)
        taxon = child_trend_taxon(taxon_name)

        product_ids = query_products(date)
        products_with_vga_ids = query_products_with_vga(date)

        taxon.repopulate(product_ids, products_with_vga_ids)
      end

      def query_products(date)
        Spree::Product.includes(:maisonette_variant_group_attributes)
                      .where(available_on: date..Date.current.end_of_day,
                             maisonette_variant_group_attributes:
                               { id: nil })
                      .purchasable.ids
      end

      def query_products_with_vga(date)
        Maisonette::VariantGroupAttributes.purchasable
                                          .where(available_on: date..Date.current.end_of_day)
                                          .pluck(:id, :product_id)
      end
    end
  end
end
