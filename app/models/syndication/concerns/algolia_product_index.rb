# frozen_string_literal: true

module Syndication
  module Concerns
    module AlgoliaProductIndex # rubocop:disable Metrics/ModuleLength
      extend ActiveSupport::Concern

      PL_BRANDS = ['Maison Me', 'Neon Rebels', 'Marvel’s Spidey and His Amazing Friends'].freeze

      ALGOLIA_PRODUCT_ATTRIBUTES = [
        :manufacturer_id,
        :image,
        :side_image,
        :title,
        :slug,
        :brand,
        :brand_slug,
        :product_type,
        :categories,
        :categories_slug,
        :color,
        :text,
        :variants,
        :variants_count,
        :available_on_to_i,
        :low_stock,
        :gender,
        :price_min,
        :price_max,
        :margin,
        :monogrammable,
        :trends,
        :trends_slug,
        :edits,
        :total_sales,
        :true_total_sales,
        :lifetime_total_sales,
        :on_sale,
        :best_sellers_today,
        :best_sellers_this_week,
        :best_sellers_this_month,
        :best_sellers_this_season,
        :best_sellers_this_year,
        :best_sellers_all_time,
        :new_in_today,
        :new_in_this_week,
        :new_in_this_month,
        :new_in_six_weeks,
        :size_broken,
        :private_label_brand,
        :season_year,
        :holiday,
        :core,
        :exclusive_type

      ].freeze

      ALGOLIA_VARIANT_ATTRIBUTES = [:maisonette_sku,
                                    :boutique,
                                    :maisonette_retail,
                                    :maisonette_sale,
                                    :size,
                                    :age_range,
                                    :clothing_sizes,
                                    :shoe_sizes].freeze

      # rubocop:disable Metrics/BlockLength
      included do
        include AlgoliaSearch

        algoliasearch index_name: Maisonette::Config.fetch('algolia.product_index'),
                      if: :is_product,
                      id: :master_or_variant_id,
                      auto_index: true,
                      enqueue: :trigger_algolia_worker,
                      disable_indexing: Rails.env.test? do
          attributes ALGOLIA_PRODUCT_ATTRIBUTES

          add_attribute(:percent_off) { percent_off.presence&.to_i }

          attributesToRetrieve %w[* -available_on_to_i -edits]

          searchableAttributes %w[
            unordered(title)
            unordered(brand)
            unordered(color)
            unordered(product_type)
            unordered(variants.boutique)
            unordered(variants.size)
            unordered(variants.age_range)
            unordered(variants.clothing_sizes)
            unordered(variants.shoe_sizes)
            unordered(text)
          ]

          attributesForFaceting %w[
            searchable(brand)
            searchable(brand_slug)
            searchable(categories)
            searchable(categories.lvl0)
            searchable(categories.lvl1)
            searchable(categories.lvl2)
            searchable(categories_slug.lvl0)
            searchable(categories_slug.lvl1)
            searchable(categories_slug.lvl2)
            searchable(trends_slug)
            title
            product_type
            on_sale
            gender
            color
            slug
            monogrammable
            variants.boutique
            variants.size
            variants.age_range
            variants.clothing_sizes
            variants.shoe_sizes
            variants.maisonette_sale
            filterOnly(available_on_to_i)
            edits
            trends
            best_sellers_today
            best_sellers_this_week
            best_sellers_this_month
            best_sellers_this_season
            best_sellers_this_year
            best_sellers_all_time
            new_in_today
            new_in_this_week
            new_in_this_month
            new_in_six_weeks

            private_label_brand
            season_year
            low_stock
            holiday
            core
            exclusive_type
          ]

          numericAttributesForFiltering %w[
            variants.maisonette_sale
            percent_off
          ]
        end

        def self.trigger_algolia_worker(record, remove)
          return unless record.is_product

          Algolia::SyncProductWorker.perform_async(record.master_or_variant_id, remove)
        end

        def variants
          Syndication::Product.where(manufacturer_id: manufacturer_id, is_product: false)
                              .select(ALGOLIA_VARIANT_ATTRIBUTES)
                              .map { |variant| variant.attributes.except('id') }
        end

        def will_save_change_to_variants?
          return unless is_product

          # note that updated_at has not changed yet because this runs before that is updated.
          # since we update the variants first this means that if the variant was updated,
          # then updated_at will be less than algolia_attributes_updated_at
          Syndication::Product.where(manufacturer_id: manufacturer_id, is_product: false)
                              .where('algolia_attributes_updated_at >= ?', updated_at)
                              .any?
        end

        def categories # rubocop:disable Metrics/MethodLength
          return unless category

          lvl0 = []
          lvl1 = []
          lvl2 = []

          category&.each do |split_category|
            category_level = case split_category.count('>')
                             when 0
                               lvl0
                             when 1
                               lvl1
                             when 2
                               lvl2
                             else
                               [] # do nothing
                             end
            category_level << split_category.strip
          end

          { lvl0: lvl0,
            lvl1: lvl1,
            lvl2: lvl2 }
        end

        def categories_slug # rubocop:disable Metrics/MethodLength
          return unless category

          lvl0 = []
          lvl1 = []
          lvl2 = []

          category&.each do |split_category|
            category_level = case split_category.count('>')
                             when 0
                               lvl0
                             when 1
                               lvl1
                             when 2
                               lvl2
                             else
                               [] # do nothing
                             end
            category_level << split_category.strip
          end
          {
            lvl0: lvl0.map { |category| to_taxon_url(category.strip, Spree::Taxonomy::CATEGORY) },
            lvl1: lvl1.map { |categories| category_slug_tree(categories.split('>')).join(' > ') },
            lvl2: lvl2.map { |categories| category_slug_tree(categories.split('>')).join(' > ') }
          }
        end

        def category_slug_tree(categories)
          categories.map { |c| to_taxon_url(c.strip, Spree::Taxonomy::CATEGORY) }
        end

        def will_save_change_to_categories_slug?; end

        def trends_slug
          return unless trends

          trends.map { |name| to_taxon_url(name, Spree::Taxonomy::TRENDS) }
        end

        def will_save_change_to_trends_slug?; end

        def brand_slug
          return unless brand

          to_taxon_url(brand, Spree::Taxonomy::BRAND)
        end

        def will_save_change_to_brand_slug?; end

        def edits_slug; end

        def to_taxon_url(name, taxon_name)
          taxonomy = Spree::Taxonomy.find_by(name: taxon_name)
          taxon = Spree::Taxon.find_by(name: name, taxonomy: taxonomy)
          return unless taxon

          taxon.permalink_part
        end

        def edits
          return unless self[:edits]

          self[:edits].map { |name| to_taxon_url(name, Spree::Taxonomy::EDITS) }
        end

        def will_save_change_to_categories?
          will_save_change_to_category?
        end

        def available_on_to_i
          return unless available_on

          DateTime.parse(available_on).to_i
        end

        def will_save_change_to_available_on_to_i?
          will_save_change_to_available_on?
        end

        def low_stock
          inventory_status == I18n.t('total_on_hand.statuses.low_inventory')
        end

        def will_save_change_to_low_stock?
          will_save_change_to_inventory_status?
        end

        def title
          product_name
        end

        def will_save_change_to_title?
          will_save_change_to_product_name?
        end

        def text
          vendor_sku_description
        end

        def will_save_change_to_text?
          will_save_change_to_vendor_sku_description?
        end

        def best_sellers_today
          return false unless trends

          trends.include? Spree::Taxon::SELLING_FAST_TODAY
        end

        def will_save_change_to_best_sellers_today?
          will_save_change_to_trends?
        end

        def best_sellers_this_week
          return false unless trends

          trends.include? Spree::Taxon::SELLING_FAST_THIS_WEEK
        end

        def will_save_change_to_best_sellers_this_week?
          will_save_change_to_trends?
        end

        def best_sellers_this_month
          return false unless trends

          trends.include? Spree::Taxon::SELLING_FAST
        end

        def will_save_change_to_best_sellers_this_month?
          will_save_change_to_trends?
        end

        def best_sellers_this_season
          return false unless trends

          trends.include? Spree::Taxon::BEST_SELLERS_THIS_SEASON
        end

        def will_save_change_to_best_sellers_this_season?
          will_save_change_to_trends?
        end

        def best_sellers_this_year
          return false unless trends

          trends.include? Spree::Taxon::BEST_SELLERS
        end

        def will_save_change_to_best_sellers_this_year?
          will_save_change_to_trends?
        end

        def best_sellers_all_time
          return false unless trends

          trends.include? Spree::Taxon::ALL_TIME_BEST_SELLERS
        end

        def will_save_change_to_best_sellers_all_time?
          will_save_change_to_trends?
        end

        def new_in_today
          return false unless trends

          trends.include? Spree::Taxon::NEW_TODAY
        end

        def will_save_change_to_new_in_today?
          will_save_change_to_trends?
        end

        def new_in_this_week
          return false unless trends

          trends.include? Spree::Taxon::NEW_THIS_WEEK
        end

        def will_save_change_to_new_in_this_week?
          will_save_change_to_trends?
        end

        def new_in_this_month
          return false unless trends

          trends.include? Spree::Taxon::JUST_IN
        end

        def will_save_change_to_new_in_this_month?
          will_save_change_to_trends?
        end

        def new_in_six_weeks
          return false unless trends

          trends.include? Spree::Taxon::NEW_IN_SIX_WEEKS
        end

        def will_save_change_to_new_in_six_weeks?
          will_save_change_to_trends?
        end

        def private_label_brand
          PL_BRANDS.include?(brand)
        end

        def will_save_change_to_private_label_brand?; end

        def season_year
          season
        end

        def will_save_change_to_season_year?; end

        def core
          season == 'CORE' ? 'Core' : 'Non-Core'
        end

        def will_save_change_to_core?; end

        def exclusive_type
          exclusive_definition
        end

        def will_save_change_to_exclusive_type?; end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end
