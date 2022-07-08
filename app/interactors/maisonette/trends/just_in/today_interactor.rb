# frozen_string_literal: true

module Maisonette
  module Trends
    module JustIn
      class TodayInteractor < ApplicationInteractor
        include JustInHelper

        def call
          update_just_in_trend(taxon_name: Spree::Taxon::NEW_TODAY, date: 2.days.ago)
        end
      end
    end
  end
end
