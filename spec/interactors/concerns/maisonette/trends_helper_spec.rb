# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::TrendsHelper do
  let(:described_class) { FakeTrendsInteractor }

  describe '#trend_taxonomy' do
    let(:trends_taxonomy) { instance_double Spree::Taxon, name: 'Trends' }

    before do
      allow(Spree::Taxonomy).to(
        receive(:find_or_create_by!).with(name: Spree::Taxonomy::TRENDS).and_return(trends_taxonomy)
      )
    end

    it 'finds_or_creates and returns the TRENDS taxonomy' do
      expect(described_class.new.send(:trends_taxonomy)).to eq trends_taxonomy
    end
  end

  describe '#child_trend_taxon' do
    subject(:child_trend_taxon) { fake_trends_interactor.send :child_trend_taxon, taxon_name }

    let(:fake_trends_interactor) { described_class.new }
    let(:taxon_name) { 'Just In Today' }

    let(:trends_taxonomy) { instance_double Spree::Taxon, root: root_trends_taxon }
    let(:root_trends_taxon) { instance_double Spree::Taxon }
    let(:just_in_trend_taxon) { instance_double Spree::Taxon, name: 'Just In Today' }

    before do
      allow(fake_trends_interactor).to receive_messages(trends_taxonomy: trends_taxonomy)
      allow(Spree::Taxon).to receive_messages(find_or_create_by!: just_in_trend_taxon)

      child_trend_taxon
    end

    it 'finds_or_creates the given taxon name' do
      expect(Spree::Taxon).to have_received(:find_or_create_by!).with(name: taxon_name,
                                                                      taxonomy: trends_taxonomy,
                                                                      parent: trends_taxonomy.root)
    end

    it 'returns the child trend taxon' do
      expect(child_trend_taxon).to eq just_in_trend_taxon
    end
  end
end

class FakeTrendsInteractor
  include Maisonette::TrendsHelper
end
