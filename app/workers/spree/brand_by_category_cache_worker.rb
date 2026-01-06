# frozen_string_literal: true

module Spree
    class BrandByCategoryCacheWorker
    include Sidekiq::Worker

    def perform
      category_taxons.each do |taxon|
        key = Maisonette::Config.brand_by_category_cache_key_prefix + taxon.permalink_part
        Rails.cache.write key, brand_taxons_by_category(taxon), cache_options
      end
    end

    private

    def category_taxons
      Spree::Taxon.category_taxons.where(depth: 1, hidden: false)
    end

    def brand_taxons_by_category(taxon)
      Spree::Taxon.brands_by_category(taxon).order(:permalink).to_json
    end

    def cache_options
      { expires_in: 24.hours, race_condition_ttl: 60.seconds }
    end
  end
end
