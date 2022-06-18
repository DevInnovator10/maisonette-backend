# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::BrandByCategoryCacheWorker do
  let(:worker) { described_class.new }
  let(:category_taxons_query) { class_double Spree::Taxon }
  let(:category_taxons) { [category_taxon] }
  let(:category_taxon) { create :taxon }

  describe '#perform' do
    before do
      allow(Spree::Taxon).to receive(:category_taxons).and_return category_taxons_query
      allow(category_taxons_query).to receive(:where).and_return category_taxons
    end

    it 'queries for the correct taxons' do
      worker.perform
      expect(Spree::Taxon).to have_received :category_taxons
      expect(category_taxons_query).to have_received(:where).with(depth: 1, hidden: false)
    end

    context 'when successful' do
      let(:brand_taxons_query) { class_double Spree::Taxon, order: brand_taxons }
      let(:brand_taxons) { [brand_taxon] }
      let(:brand_taxon) { create :taxon }

      let(:cache_options) { { expires_in: 24.hours, race_condition_ttl: 60.seconds } }
      let(:key) { Maisonette::Config.brand_by_category_cache_key_prefix + category_taxon.permalink_part }

      before do
        allow(worker).to receive(:category_taxons).and_return category_taxons
        allow(Spree::Taxon).to receive(:brands_by_category).and_return brand_taxons_query
        allow(Rails.cache).to receive(:write).and_call_original
        worker.perform
      end

      it 'populates cache for the taxons', cache: true do
        expect(Rails.cache).to have_received(:write).with(key, brand_taxons.to_json, cache_options)
      end
    end
  end
end
