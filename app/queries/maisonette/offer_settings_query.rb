# frozen_string_literal: true

module Maisonette
  class OfferSettingsQuery
    ALLOWED_PARAMS = %w[
      product_name maisonette_sku_or_vendor_sku_or_variant_sku in_stock
      vendors_in vendors_not_in taxons_in taxons_not_in vendor_name
    ].freeze

    def initialize(relation = Spree::OfferSettings)
      @scoped = relation.all
    end

    def call(params) # rubocop:disable Metrics/AbcSize
      allowed_params = prepare_params(params || {})
      return @scoped.none if allowed_params.empty?

      @scoped = search_by_product_name(allowed_params['product_name'])
      @scoped = search_by_sku(allowed_params['maisonette_sku_or_vendor_sku_or_variant_sku'])
      @scoped = search_by_vendors(allowed_params['vendors_in'])
      @scoped = search_by_excluded_vendors(allowed_params['vendors_not_in'])
      @scoped = search_by_taxons(allowed_params['taxons_in'])
      @scoped = search_by_excluded_taxons(allowed_params['taxons_not_in'])
      @scoped = search_by_vendor_name(allowed_params['vendor_name'])
      @scoped = search_by_in_stock(allowed_params['in_stock'])

      @scoped
    end

    private

    def prepare_params(params)
      params.select { |k, _| k.in?(ALLOWED_PARAMS) }
    end

    def search_by_product_name(product_name)
      return @scoped if product_name.blank?

      @scoped.joins(variant: :product).where('spree_products.name LIKE ?', "%#{product_name}%")
    end

    def search_by_sku(sku)
      return @scoped if sku.blank?

      @scoped = @scoped.joins(:variant)
      @scoped.where('spree_offer_settings.vendor_sku LIKE ?', "%#{sku}%")
             .or(@scoped.where('spree_offer_settings.maisonette_sku LIKE ?', "%#{sku}%"))
             .or(@scoped.where('spree_variants.sku LIKE ?', "%#{sku}%"))
    end

    def search_by_vendors(vendors_ids)
      return @scoped if vendors_ids.blank?

      @scoped.where(vendor_id: vendors_ids.split(','))
    end

    def search_by_excluded_vendors(vendors_ids)
      return @scoped if vendors_ids.blank?

      @scoped.where.not(vendor_id: vendors_ids.split(','))
    end

    def search_by_taxons(taxons_ids)
      return @scoped if taxons_ids.blank?

      @scoped.joins(variant: { product: :classifications })
             .where(spree_products_taxons: { taxon_id: taxons_ids.split(',') })
    end

    def search_by_excluded_taxons(taxons_ids)
      return @scoped if taxons_ids.blank?

      condition = <<-SQL
        spree_products.id NOT IN (
          SELECT spree_products_taxons.product_id
          FROM spree_products_taxons
          WHERE spree_products_taxons.product_id = spree_products.id AND spree_products_taxons.taxon_id IN (?)
        )
      SQL

      @scoped.joins(variant: :product).where(condition, taxons_ids.split(','))
    end

    def search_by_vendor_name(vendor_name)
      return @scoped if vendor_name.blank?

      @scoped.joins(:vendor).where('spree_vendors.name LIKE ?', "%#{vendor_name}%")
    end

    def search_by_in_stock(in_stock)
      return @scoped if in_stock != '1'

      @scoped.joins(variant: :stock_items)
             .joins(
               <<-SQL
                 INNER JOIN spree_stock_locations ON
                   spree_stock_locations.id = spree_stock_items.stock_location_id
                   AND
                   spree_stock_locations.vendor_id = spree_offer_settings.vendor_id
               SQL
             )
             .where('spree_stock_items.count_on_hand > 0')
    end
  end
end
