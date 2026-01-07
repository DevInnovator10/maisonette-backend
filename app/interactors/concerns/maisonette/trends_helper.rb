# frozen_string_literal: true

module Maisonette
  module TrendsHelper
    private

    def trends_taxonomy
      @trends_taxonomy ||= Spree::Taxonomy.find_or_create_by!(name: Spree::Taxonomy::TRENDS)
    end

    def child_trend_taxon(taxon_name)
      Spree::Taxon.find_or_create_by!(name: taxon_name,
                                      taxonomy: trends_taxonomy,
                                      parent: trends_taxonomy.root)
    end
  end
end
