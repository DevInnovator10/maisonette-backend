# frozen_string_literal: true

module Algolia
  class SyncEditsRulesPositionWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(file_name)
      json_file = read_file(file_name)
      edits_scope = Spree::Taxon.joins(:taxonomy).where(spree_taxonomies: { name: Spree::Taxonomy::EDITS })
      @rules = []
      json_file['landingPages'].each do |sli_hash|
        taxon = edits_scope.find_by(name: sli_hash['name'])
        next unless taxon

        products_list = sli_hash['actions']['promote']
        @rules << build_rule(taxon, products_list)
      end
      return unless @rules

      index.save_rules(@rules)
    end

    private

    def build_rule(taxon, products_list) # rubocop:disable Metrics/MethodLength
      {
        objectID: taxon.algolia_rule_object_id,
        conditions: [{
          alternatives: false,
          anchoring: 'is',
          pattern: '',
          filters: "edits: #{taxon.permalink.split('/').last}"
        }],
        consequence: {
          promote: products(products_list, taxon).compact,
          userData: {
            name: taxon.name
          }
        },
        enabled: true
      }
    end

    def products(products_list, taxon)
      products_list.first(300).each_with_index.map do |product, position|
        slug = product['url'].split('/').last
        product = taxon.products.find_by(slug: slug)
        master_variant_id = product&.master&.id
        next unless master_variant_id

        {
          "objectID": master_variant_id.to_s,
          "position": position
        }
      end
    end

    def index
      @index ||= Syndication::Product.algolia_index
    end

    def read_file(file_name)
      file = S3.get("lpc-to-edits/#{file_name}", bucket: Maisonette::Config.fetch('aws.bucket'))
      JSON.parse(file)
    end
  end
end
