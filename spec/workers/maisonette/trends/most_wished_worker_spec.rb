# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Trends::MostWishedWorker do
  before do
    allow(Maisonette::Trends::MostWishedOrganizer).to(receive(:call!).and_return(true))

    described_class.new.perform
  end

  it 'calls Maisonette::Trends::MostWishedOrganizer' do
    expect(Maisonette::Trends::MostWishedOrganizer).to have_received(:call!)
  end
end
