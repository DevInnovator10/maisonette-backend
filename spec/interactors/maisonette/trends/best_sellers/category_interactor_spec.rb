# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Trends::BestSellers::CategoryInteractor do
  describe '#call' do
    let(:interactor) { described_class.new }
    let(:taxons_with_insight_tracking) { class_double Spree::Taxon }
    let(:kids_taxon) { instance_double Spree::Taxon, name: 'Kids', track_insights: true }
    let(:girls_taxon) { instance_double Spree::Taxon, name: 'Girls', track_insights: true }

    before do
      allow(interactor).to receive(:update_category_trend)
      allow(Spree::Taxon).to receive(:where).with(track_insights: true).and_return(taxons_with_insight_tracking)
      allow(taxons_with_insight_tracking).to receive(:find_each).and_yield(kids_taxon).and_yield(girls_taxon)

      interactor.call
    end

    it 'calls update_category_trend with taxons that are tracking insights on' do
      expect(interactor).to(
        have_received(:update_category_trend).with(taxon_name: Spree::Taxon::TRENDING_IN,
                                                   trend_name: Spree::Taxon::BEST_SELLERS_THIS_SEASON,
                                                   category: kids_taxon)
      )
      expect(interactor).to(
        have_received(:update_category_trend).with(taxon_name: Spree::Taxon::TRENDING_IN,
                                                   trend_name: Spree::Taxon::BEST_SELLERS_THIS_SEASON,
                                                   category: girls_taxon)
      )
    end
  end
end
