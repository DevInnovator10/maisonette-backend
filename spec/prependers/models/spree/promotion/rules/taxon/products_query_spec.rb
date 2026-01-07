# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Promotion::Rules::Taxon::ProductsQuery do
    let(:described_class) { Spree::Promotion::Rules::Taxon }

  let(:rule) { described_class.new(rule_options) }

  describe '#products_query' do
    subject(:products_query) { rule.products_query(scope) }

    let(:scope) { Spree::Product.all }
    let(:included_taxon) { create(:taxon) }
    let(:excluded_taxon) { create(:taxon) }
    let(:products_with_included_taxon) { create_list(:product, 2, taxons: [included_taxon]) }
    let(:product_with_mix_taxons) { create(:product, taxons: [included_taxon, excluded_taxon]) }
    let(:products_with_excluded_taxon) { create_list(:product, 2, taxons: [excluded_taxon]) }
    let(:products_without_taxon) { create_list(:product, 2) }

    before do
      products_with_excluded_taxon
      products_with_included_taxon
      product_with_mix_taxons
      products_without_taxon
    end

    context 'when the match policy is any' do
      let(:rule_options) { { preferred_match_policy: 'any', taxons: [included_taxon] } }

      it 'returns a collection without the excluded products' do
        expect(products_query.pluck(:id)).to match_array(
          products_with_included_taxon.map(&:id) << product_with_mix_taxons.id
        )
      end
    end

    context 'when the match policy is all' do
      let(:rule_options) { { preferred_match_policy: 'all', taxons: [included_taxon] } }

      it 'returns a collection without the excluded products' do
        expect(products_query.pluck(:id)).to match_array(
          products_with_included_taxon.map(&:id) << product_with_mix_taxons.id
        )
      end
    end

    context 'when the match policy is none' do
      let(:rule_options) { { preferred_match_policy: 'none', taxons: [excluded_taxon] } }

      it 'returns a collection without the excluded products' do
        expect(products_query.pluck(:id)).to match_array(
          products_with_included_taxon.map(&:id) + products_without_taxon.map(&:id)
        )
      end
    end

    context 'when the match policy is invalid' do
      let(:rule_options) { { preferred_match_policy: 'invalid' } }

      it 'raises an exception' do
        expect { products_query }.to raise_exception(RuntimeError, 'unexpected match policy: "invalid"')
      end
    end
  end
end
