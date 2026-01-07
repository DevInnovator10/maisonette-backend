# frozen_string_literal: true

module Spree::Api::TaxonsController::Navigation
  def self.prepended(base)
    base.const_set(
      'NAV_ATTRS',
      [:id, :name, :navigation_url, :parent_id, :lft, :depth, :highlight,
       :header_link, :add_flair, :view_all_url_override, :icon_url_original].freeze
    )
  end

  def navigation_menu_taxons
    render json: cached_mapped_navigation_taxons
  end

  private

  def cached_mapped_navigation_taxons
    nav_taxons = Rails.cache.read navigation_cache_key
    return nav_taxons if nav_taxons.present? && nav_taxons.is_a?(Array)

    Rails.cache.write(
      navigation_cache_key, mapped_navigation_taxons, expires_in: 24.hours, race_condition_ttl: 60.seconds
    )
    Rails.cache.read navigation_cache_key
  end

  def mapped_navigation_taxons
    if navigation_variation_header
      navigation_variation
    else
      default_navigation
    end
  end

  def default_navigation
    navigation_taxons.map do |nav_bar_taxon|
      [
        taxon_attrs(nav_bar_taxon),
        nav_bar_taxon.children.visible.map do |header_taxon|
          [
            taxon_attrs(header_taxon),
            header_taxon.children.visible.map { |menu_item_taxon| taxon_attrs(menu_item_taxon) }
          ]
        end
      ]
    end.flatten
  end

  def navigation_variation # rubocop:disable Metrics/MethodLength
    navigation_taxons.map do |nav_bar_taxon|
      [
        taxon_attrs(nav_bar_taxon),
        nav_bar_taxon.children.visible.map do |header_taxon|
          [
            taxon_attrs(header_taxon),
            header_taxon.children.visible.map do |node_taxon|
              [
                taxon_attrs(node_taxon),
                node_taxon.children.visible.map { |last_node| taxon_attrs(last_node) }
              ]
            end
          ]
        end
      ]
    end.flatten
  end

  def navigation_taxons
    @navigation_taxons ||= Spree::Taxon.includes(:taxonomy)
                                       .navigation_taxons(navigation_variation_header).where(depth: 1)
  end

  def taxon_attrs(taxon)
    taxon.slice(*Spree::Api::TaxonsController::NAV_ATTRS)
  end

  def navigation_cache_key
    Spree::Taxonomy.navigation_cache_key(navigation_variation_header || Spree::Taxonomy::NAVIGATION)
  end

  def navigation_variation_header
    request.headers['X-Variation'].presence
  end
end
