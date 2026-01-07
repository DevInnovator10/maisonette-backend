# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Trends::BestSellers::ThisWeekInteractor, freeze_time: true do
    describe '#call' do
    let(:interactor) { described_class.new }

    before do
      allow(interactor).to receive(:update_best_sellers_trend)

      interactor.call
    end

    it 'calls update_best_sellers_trend' do
      expect(interactor).to(
        have_received(:update_best_sellers_trend).with(taxon_name: Spree::Taxon::SELLING_FAST_THIS_WEEK,
                                                       date: 1.week.ago)
      )
    end
  end
end
