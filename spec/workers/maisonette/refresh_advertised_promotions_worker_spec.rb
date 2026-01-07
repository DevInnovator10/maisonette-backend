# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::RefreshAdvertisedPromotionsWorker do
  before do
    allow(Maisonette::RefreshAdvertisedPromotionsInteractor).to(receive(:call!).and_return(true))

    described_class.new.perform
  end

  it 'calls Maisonette::RefreshAdvertisedPromotionsInteractor' do
    expect(Maisonette::RefreshAdvertisedPromotionsInteractor).to have_received(:call!)
  end
end
