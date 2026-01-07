# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Trends::BestSellersWorker do
  before do
    allow(Maisonette::Trends::BestSellersOrganizer).to(receive(:call!).and_return(true))

    described_class.new.perform
  end

  it 'calls Maisonette::Trends::BestSellersOrganizer' do
    expect(Maisonette::Trends::BestSellersOrganizer).to have_received(:call!)
  end
end
