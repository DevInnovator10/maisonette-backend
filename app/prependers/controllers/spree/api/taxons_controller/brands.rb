# frozen_string_literal: true

module Spree::Api::TaxonsController::Brands
  def self.prepended(base)
    base.before_action :validate_taxon, only: :brands_by_category
  end

  def brands
    payload = Rails.cache.fetch('purchasable_brands', cache_options) { purchasable_brands }
    render json: payload, status: :ok
  end

  def brands_by_category
    return render_from_cache if cached_response

    Rails.logger.info "Unable to find brand by category cache for #{params[:taxon_key]}"
    payload = Rails.cache.fetch(brands_by_category_key, cache_options) { brand_taxons_by_category }

    render json: payload, status: :ok
  end

  private

  def render_from_cache
    render json: cached_response, status: :ok
  end

  def cached_response
    @cached_response ||= Rails.cache.read brands_by_category_key
  end

  def validate_taxon
    return if category_taxon.present?

    render json: { message: "invalid taxon #{params[:taxon_key]}" }, status: :unprocessable_entity
  end

  def category_taxon
    @category_taxon ||= begin
      root_key = Spree::Taxonomy::CATEGORY.parameterize.underscore.downcase
      Spree::Taxon.find_by(permalink: "#{root_key}/#{params[:taxon_key]}")
    end
  end

  def brand_taxons_by_category
    Spree::Taxon.brands_by_category(category_taxon).order(:permalink).to_json
  end

  def brands_by_category_key
    Maisonette::Config.brand_by_category_cache_key_prefix + params[:taxon_key]
  end

  def purchasable_brands
    Spree::Taxon.purchasable_brands.order(:permalink).to_json
  end

  def cache_options
    { expires_in: 24.hours, race_condition_ttl: 60.seconds }
  end
end
