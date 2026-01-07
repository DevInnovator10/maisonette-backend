# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Navigation Taxons', type: :request do
  let(:nav_attrs) { Spree::Api::TaxonsController::NAV_ATTRS }

  context 'when variation' do
    let(:variation) { create :taxonomy, name: 'NavigationV1' }
    let!(:toys) { create :taxon, parent: variation.root, taxonomy: variation, name: 'Toys' }

    let(:do_request) { get '/api/taxons/nav', headers: { 'X-Variation': variation.name, Accept: 'application/json' } }

    before { Rails.cache.delete Spree::Taxonomy.navigation_cache_key(variation.name) }

    it "returns attributes #{Spree::Api::TaxonsController::NAV_ATTRS}" do
      do_request

      expect(json_response).to eq [toys.slice(*nav_attrs)]
    end

    it 'returns taxons only from NavigationV1 taxonomy' do
      do_request

      json_response.each do |taxon|
        expect(Spree::Taxon.find(taxon['id']).taxonomy).to eq variation
      end
    end
  end

  context 'when no variation' do
    let(:navigation) { create :taxonomy, name: 'Navigation' }
    let!(:kids) { create :taxon, parent: navigation.root, taxonomy: navigation, name: 'Kids' }

    let(:do_request) { get '/api/taxons/nav', headers: { Accept: 'application/json' } }

    before { Rails.cache.delete(Spree::Taxonomy.navigation_cache_key(Spree::Taxonomy::NAVIGATION)) }

    it "returns attributes #{Spree::Api::TaxonsController::NAV_ATTRS}" do
      do_request

      expect(json_response).to eq [kids.slice(*nav_attrs)]
    end

    it 'returns taxons only from Navigation taxonomy' do
      do_request

      json_response.each do |taxon|
        expect(Spree::Taxon.find(taxon['id']).taxonomy).to eq navigation
      end
    end

    it 'does not return taxons with hidden ancestor' do
      baby = create :taxon, parent: navigation.root, taxonomy: navigation, name: 'Baby', hidden: true
      clothing = create :taxon, parent: baby, taxonomy: navigation, name: 'Clothing'
      boys = create :taxon, parent: clothing, taxonomy: navigation, name: 'Boys'

      do_request

      expect(json_response).not_to include boys.slice(*nav_attrs)
      expect(json_response).to eq [kids.slice(*nav_attrs)]
    end

    context 'when a taxon has a view all url override' do
      it 'returns the view all url override' do
        create :taxon, parent: kids, taxonomy: navigation, name: 'Boys', view_all_url_override: 'boys_overridden'

        do_request

        expect(json_response).to include(hash_including('name' => 'Boys',
                                                        'view_all_url_override' => 'boys_overridden'))
      end
    end

    it 'caches the request' do
      allow(Spree::Taxon).to receive(:navigation_taxons).and_call_original
      2.times { get '/api/taxons/nav', headers: { Accept: 'application/json' } }
      expect(Spree::Taxon).to have_received(:navigation_taxons).once
    end

    context 'when there is a previously cached response' do
      subject { json_response }

      let(:bad_cache) { 'foo' }

      before do
        Rails.cache.write(Spree::Taxonomy.navigation_cache_key(Spree::Taxonomy::NAVIGATION), bad_cache)
        do_request
      end

      it 'stores a new cached value' do
        expect(Rails.cache.read(Spree::Taxonomy.navigation_cache_key(Spree::Taxonomy::NAVIGATION))).not_to eq bad_cache
        expect(json_response).to eq Array.wrap kids.slice(*Spree::Api::TaxonsController::NAV_ATTRS)
      end

      context 'when the response is an empty array' do
        let(:bad_cache) { [] }

        it { is_expected.not_to eq [] }
        it { is_expected.to eq Array.wrap kids.slice(*Spree::Api::TaxonsController::NAV_ATTRS) }
      end

      context 'when the response is nil' do
        let(:bad_cache) { nil }

        it { is_expected.not_to be_nil }
        it { is_expected.to eq Array.wrap kids.slice(*Spree::Api::TaxonsController::NAV_ATTRS) }
      end
    end
  end
end
