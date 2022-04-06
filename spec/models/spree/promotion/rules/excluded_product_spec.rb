# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Promotion::Rules::ExcludedProduct do
  let(:rule) { described_class.new(rule_options) }
  let(:order) { build(:order) }
  let(:rule_options) { {} }

  describe '#applicable' do
    it 'is applicable to orders' do
      expect(rule.applicable?(order)).to be true
    end
  end

  describe '#eligible?' do
    it 'returns true' do
      expect(rule.eligible?(order)).to be true
    end
  end

  describe '#actionable?' do
    context 'when excluded products' do
      let(:rule_options) { { products: [excluded.variant.product] } }
      let(:excluded) { build_stubbed(:line_item) }

      it 'returns false' do
        expect(rule.actionable?(excluded)).to be false
      end
    end

    context 'when no excluded products' do
      let(:excluded) { build_stubbed(:line_item) }

      it 'returns true' do
        expect(rule.actionable?(excluded)).to be true
      end
    end
  end

  describe '#product_ids_string' do
    let(:rule_options) { { products: [excluded.variant.product] } }
    let(:product_ids_string) { excluded.variant.product.id.to_s }
    let(:excluded) { build_stubbed(:line_item) }

    it 'joins product ids' do
      expect(rule.product_ids_string).to eq product_ids_string
    end
  end

  describe '#product_ids_string=' do
    let(:rule_options) { { products: [excluded.variant.product] } }
    let(:product_ids_string) { excluded.variant.product.id.to_s }
    let(:excluded) { build_stubbed(:line_item) }

    it 'convert to array a comma item separated string' do
      rule.product_ids_string = product_ids_string

      expect(rule.product_ids).to eq [excluded.variant.product.id]
    end
  end

  describe '#products_query' do
    subject(:products_query) { rule.products_query(scope) }

    let(:scope) { Spree::Product.all }
    let(:included_products) { create_list(:product, 2) }
    let(:excluded_products) { create_list(:product, 2) }

    let(:rule_options) { { products: excluded_products } }

    before do
      included_products
      excluded_products
    end

    it 'returns a collection without the excluded products' do
      expect(Spree::Product.count).to eq(4)
      expect(products_query.pluck(:id)).to match_array(included_products.map(&:id))
    end
  end
end
