# frozen_string_literal: true

module Spree::Product::Base
  def self.prepended(base) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    base.ransackable_associations.push 'stock_items'
    base.const_set(
      'PRODUCT_BADGE_PRIORITIES',
      ['Selling Fast', 'Exclusive', 'Just In', 'Monogram', 'Most Wished', 'On Sale'].freeze
    )
    base.delegate :id, to: :master, prefix: true

    base.has_one :age_range_classification,
                 -> { joins(taxon: :taxonomy).where(spree_taxonomies: { name: Spree::Taxonomy::AGE_RANGE }) },
                 class_name: 'Spree::Classification'
    base.has_one :age_range, -> { joins(:taxonomy) }, through: :age_range_classification, source: :taxon

    base.has_one :brand_classification,
                 -> { joins(taxon: :taxonomy).where(spree_taxonomies: { name: Spree::Taxonomy::BRAND }) },
                 class_name: 'Spree::Classification'
    base.has_one :brand, -> { joins(:taxonomy) }, through: :brand_classification, source: :taxon

    base.has_one :color_classification,
                 -> { joins(taxon: :taxonomy).where(spree_taxonomies: { name: Spree::Taxonomy::COLOR }) },
                 class_name: 'Spree::Classification'
    base.has_one :color, -> { joins(:taxonomy) }, through: :color_classification, source: :taxon

    base.has_one :gender_classification,
                 -> { joins(taxon: :taxonomy).where(spree_taxonomies: { name: Spree::Taxonomy::GENDER }) },
                 class_name: 'Spree::Classification'
    base.has_one :gender, -> { joins(:taxonomy) }, through: :gender_classification, source: :taxon

    base.has_one :main_category_classification,
                 -> { joins(taxon: :taxonomy).where(spree_taxonomies: { name: Spree::Taxonomy::MAIN_CATEGORY }) },
                 class_name: 'Spree::Classification'
    base.has_one :main_category, -> { joins(:taxonomy) }, through: :main_category_classification, source: :taxon

    base.has_one :type_classification,
                 -> { joins(taxon: :taxonomy).where(spree_taxonomies: { name: Spree::Taxonomy::PRODUCT_TYPE }) },
                 class_name: 'Spree::Classification'
    base.has_one :type, -> { joins(:taxonomy) }, through: :type_classification, source: :taxon
    base.has_many :active_sale_prices,
                  -> { merge(Spree::SalePrice.active) },
                  through: :prices,
                  source: :sale_prices,
                  class_name: 'Spree::SalePrice'
    base.has_many :maisonette_variant_group_attributes, class_name: 'Maisonette::VariantGroupAttributes'
    base.has_many :option_values, through: :maisonette_variant_group_attributes
    base.belongs_to :migrated_to, class_name: 'Maisonette::VariantGroupAttributes', optional: true
    base.has_many :salsify_import_rows,
                  class_name: 'Salsify::ImportRow',
                  foreign_key: :spree_product_id,
                  inverse_of: :spree_product
  end

  def to_s
    string = name
    string += ": #{description}" if description.present?
    string
  end

  def brand_description
    brand&.display_description
  end

  def trends
    all_taxons = taxons.children_with_parent('Trends')
                       .where(hidden: false)
                       .where.not(name: 'On Sale')
                       .pluck(:name)
                       .uniq
    all_taxons << 'On Sale' if on_sale?
    preferred = Spree::Product::PRODUCT_BADGE_PRIORITIES & all_taxons
    sorted_badge_names = preferred + (all_taxons - preferred)

    sorted_badge_names.first(3).map do |name|
      { type: name.downcase.gsub(/\s+/, ''), value: name }
    end
  end

  def discontinued?
    if maisonette_variant_group_attributes.blank?
      (!!available_until && available_until <= Time.current)
    else
      maisonette_variant_group_attributes.detect do |vga|
        vga.available_until.blank? || (vga.available_until > Time.current)
      end.blank?
    end
  end

  def on_sale?
    prices.on_sale.exists?
  end
end
