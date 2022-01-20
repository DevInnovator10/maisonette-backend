# frozen_string_literal: true

require 'with_advisory_lock'

module Salsify
  class ImportTaxonInteractor < ApplicationInteractor
    TAXONOMIES = [
      'Age Range',
      'Brand',
      'Color',
      'Gender',
      'Internal Gender',
      'Looks',
      'Product Type',
      'Season',
      'Selling Group',
      'Category',
      'Edits',
      'Main Category',
      'Type',
      'Trends'
    ].freeze

    # these taxonomies can come from Salsify or Solidus, so we will always append instead of replace
    APPENDING_TAXONOMIES = [
      'Trends',
    ].freeze

    def call
      return unless context.import_product || context.different_variant_group_attributes

      find_product_taxon_ids.uniq.compact.each do |taxon_id|
        attrs = {
          product_id: context.product.id,
          taxon_id: taxon_id,
          maisonette_variant_group_attributes_id: context.variant_group_attributes&.id
        }
        Spree::Classification.create!(attrs)
      rescue ActiveRecord::RecordInvalid
        Spree::Classification.find_by!(attrs)
      end
    end

    private

    def create_taxon!(taxon_name, parent_taxonomy, parent_taxon) # rubocop:disable Metrics/MethodLength
      taxon = nil
      Spree::Taxon.transaction do
        parent_taxon ||= Spree::Taxon.find_by!(name: parent_taxonomy.name)
        tmp_taxon = parent_taxon.children.new(name: taxon_name, taxonomy: parent_taxonomy).tap(&:set_permalink)
        lock = "find_or_create taxon #{tmp_taxon.permalink}"
        result = Spree::Taxon.with_advisory_lock(lock, transaction: true, timeout_seconds: 15) do
          taxon = Spree::Taxon.find_or_create_by!(permalink: tmp_taxon.permalink) do |new_taxon|
            new_taxon.name = taxon_name
            new_taxon.parent = parent_taxon
            new_taxon.taxonomy = parent_taxonomy
          end
        end
        context.fail!(messages: "Can't acquire advisory lock [#{__FILE__}:#{__LINE__}]") if result == false
      end
      taxon
    end

    def find_product_taxon_ids # rubocop:disable Metrics/MethodLength
      import_product_taxon_ids = []
      associated_taxon = []
      TAXONOMIES.each do |taxonomy_name|
        parent_taxonomy = Spree::Taxonomy.find_by(name: taxonomy_name)
        Sentry.capture_message("Taxonomy #{taxonomy_name} missing while importing Salsify") if parent_taxonomy.nil?
        next if parent_taxonomy.nil?

        import_product_taxon_ids += extract_product_taxon(taxonomy_name, parent_taxonomy)

        next if APPENDING_TAXONOMIES.include?(taxonomy_name)

        associated_taxon += context.product.taxons.where(taxonomy: parent_taxonomy)
      rescue StandardError => e
        Sentry.capture_exception_with_message(e, extra: { taxonomy_name: taxonomy_name, context: context })
        raise e
      end

      delete_product_taxons(associated_taxon, import_product_taxon_ids) # moved outside of loop
      import_product_taxon_ids
    end

    def delete_product_taxons(associated_taxons, import_product_taxon_ids)
      return unless associated_taxons.any?

      vga_id = context.variant_group_attributes&.id
      context.product
             .classifications
             .where(taxon: associated_taxons.map(&:id), maisonette_variant_group_attributes_id: vga_id)
             .where.not(taxon_id: import_product_taxon_ids)
             .delete_all
      associated_taxons.each(&:touch)
    end

    def extract_product_taxon(taxonomy_name, parent_taxonomy)
      context.row[taxonomy_name].to_s.split("\;").map(&:strip).map do |taxon_name|
        split_into_taxons(parent_taxonomy, taxon_name.split('>').map(&:strip))
      end.flatten
    end

    def split_into_taxons(parent_taxonomy, taxon_name_list, product_taxon_ids = [], parent_taxon = nil)
      taxon_name = taxon_name_list.shift
      taxon = create_taxon!(taxon_name, parent_taxonomy, parent_taxon)
      product_taxon_ids << taxon.id

      return product_taxon_ids if taxon_name_list.empty?

      split_into_taxons(parent_taxonomy, taxon_name_list, product_taxon_ids, taxon)
    rescue StandardError => e

      context.fail!(messages: "taxon: #{taxon_name} - error: #{e} [#{__FILE__}:#{__LINE__}]")
    end
  end
end
