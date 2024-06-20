# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Taxonomy::Base, type: :model do
  subject { described_class }

  let(:described_class) { Spree::Taxonomy }

  it { is_expected.to be_const_defined :BREADCRUMB_TAXONS }
  it { is_expected.to be_const_defined :MAIN_CATEGORY }
  it { is_expected.to be_const_defined :PRODUCT_TYPE }
  it { is_expected.to be_const_defined :SELLING_GROUP }

  describe 'validations' do
    subject { build :taxonomy }

    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe '.for_breadcrumbs' do
    let!(:category) { create :taxonomy, :main_category }
    let!(:product) { create :taxonomy, :product_type }
    let!(:group) { create :taxonomy, :selling_group }

    before { create_list :taxonomy, 3 }

    it 'returns only taxonomies in the BREADCRUMB_TAXONS constant' do
      expect(Spree::Taxonomy.for_breadcrumbs).to match_array [category, product, group]
    end
  end

  describe '.navigation_cache_key' do
    it 'returns the rails cache key' do
      expect(Spree::Taxonomy.navigation_cache_key('Navigation')).to eq 'navigation_menu_taxons'
    end
  end

  describe '#navigation?' do
    let!(:navigation) { create :taxonomy, name: 'Navigation V1' }

    it 'returns true' do
      expect(navigation.navigation?).to eq true
    end
  end

  describe '#default_navigation?' do
    let!(:navigation) { create :taxonomy, name: Spree::Taxonomy::NAVIGATION }

    it 'returns true' do
      expect(navigation.default_navigation?).to eq true
    end
  end
end
