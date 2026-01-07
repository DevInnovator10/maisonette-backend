# frozen_string_literal: true

module Maisonette
  module Trends
    module BestSellers
      class ThisMonthInteractor < ApplicationInteractor
        include BestSellersHelper

        def call
          update_best_sellers_trend(taxon_name: Spree::Taxon::SELLING_FAST, date: 1.month.ago)
        end
      end
    end
  end
end
