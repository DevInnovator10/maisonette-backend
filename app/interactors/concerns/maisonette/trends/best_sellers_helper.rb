# frozen_string_literal: true

module Maisonette
    module Trends
    module BestSellersHelper
      include TrendsHelper

      private

      def update_best_sellers_trend(taxon_name:, date:)
        taxon = child_trend_taxon(taxon_name)

        products = query_products(date)
        products_with_vga = query_products_with_vga(date)

        taxon.repopulate(
          top_percent(products),
          top_percent(products_with_vga)
        )
      end

      def top_percent(list)
        list[0...(list.count * 0.05).ceil]
      end

      def query_products(date)
        Spree::Product.joins(:orders)
                      .where(spree_orders: { completed_at: date..Time.current },
                             maisonette_variant_group_attributes: { id: nil })
                      .purchasable
                      .group(:id)
                      .order(count: :desc)
                      .ids
      end

      def query_products_with_vga(date)
        Maisonette::VariantGroupAttributes.joins(:orders)
                                          .where(spree_orders: { completed_at: date..Time.current })
                                          .purchasable
                                          .group(:id)
                                          .order(count: :desc)
                                          .pluck(:id, :product_id)
      end
    end
  end
end
