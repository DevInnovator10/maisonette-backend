# frozen_string_literal: true

module Maisonette
  module Trends
    module JustIn
      class ThisWeekInteractor < ApplicationInteractor
        include JustInHelper

        def call
          update_just_in_trend(taxon_name: Spree::Taxon::NEW_THIS_WEEK, date: 1.week.ago)
        end
      end
    end
  end
end
