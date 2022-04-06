# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Trends::JustInOrganizer do
  it { expect(described_class.new).to be_a Interactor::Organizer }

  it do
    expect(described_class.organized).to(
      eq [Maisonette::Trends::JustIn::TodayInteractor,
          Maisonette::Trends::JustIn::ThisWeekInteractor,
          Maisonette::Trends::JustIn::LastTwoMonthsInteractor,
          Maisonette::Trends::JustIn::LastSixWeeksInteractor,
          Maisonette::Trends::JustIn::CategoryInteractor]
    )
  end
end
