# frozen_string_literal: true

module Maisonette
  class SaleSkuConfigurationPresenter
    def initialize(sale)
      @sale = sale
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def call
      @sale.sale_sku_configurations.includes(:offer_settings).map do |configuration|
        {
          product_name: configuration.offer_settings.variant.product.name,
          vendor_name: configuration.offer_settings.vendor.name,
          maisonette_sku: configuration.offer_settings.maisonette_sku,
          vendor_sku: configuration.offer_settings.vendor_sku,
          percent_off: (configuration.percent_off.to_f * 100),
          maisonette_liability: configuration.maisonette_liability,
          final_sale: configuration.final_sale,
          start_date: configuration.start_date,
          end_date: configuration.end_date
        }
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
