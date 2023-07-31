# frozen_string_literal: true

module Maisonette
  module Trends
    class JustInOrganizer < ApplicationOrganizer
      organize Trends::JustIn::TodayInteractor,
               Trends::JustIn::ThisWeekInteractor,

               Trends::JustIn::LastTwoMonthsInteractor,
               Trends::JustIn::LastSixWeeksInteractor,
               Trends::JustIn::CategoryInteractor
    end
  end
end
