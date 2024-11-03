# frozen_string_literal: true

module Maisonette
  class ExportSaleSkuConfigurationsWorker < ::Maisonette::BaseSaleExportWorker
    protected

    def collection
      @collection ||= begin
        search = @sale.sale_sku_configurations.ransack(@search_query)
        search.result(distinct: true)
              .includes(:created_by, :updated_by, offer_settings: [{ variant: :product }, :vendor])
              .order(id: :desc)
      end
    end

    def csv_row_builder # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      lambda do |sale_sku|
        [
          sale_sku.offer_settings.variant.product.name,
          sale_sku.offer_settings.vendor.name,
          sale_sku.offer_settings.maisonette_sku,
          sale_sku.offer_settings.vendor_sku,
          sale_sku.percent_off.try(:*, 100),
          sale_sku.maisonette_liability,
          sale_sku.final_sale,
          sale_sku.start_date ? sale_sku.start_date.strftime('%m-%d-%Y %I:%M %p') : nil,
          sale_sku.end_date ? sale_sku.end_date.strftime('%m-%d-%Y %I:%M %p') : nil,
          sale_sku.static_sale_price,
          sale_sku.static_cost_price,
          nil
        ]
      end
    end
  end
end
