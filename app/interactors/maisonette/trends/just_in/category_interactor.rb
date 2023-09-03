# frozen_string_literal: true

module Maisonette
  module Trends
    module JustIn
      class CategoryInteractor < ApplicationInteractor
        include CategoryHelper

        def call
          Spree::Taxon.where(track_insights: true).find_each do |taxon|
            update_category_trend(taxon_name: Spree::Taxon::NEW_IN,
                                  trend_name: Spree::Taxon::JUST_IN,
                                  category: taxon)
          end
        end

      end
    end
  end
end
