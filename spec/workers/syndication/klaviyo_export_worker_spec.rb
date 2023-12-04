# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Syndication::KlaviyoExportWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:product1) { create :syndication_product }
    let(:product2) { create :syndication_product }
    let(:products) { [product1, product2] }
    let(:payload) { products.map(&:attributes).to_json }

    let(:url) { 'klaviyo/products.json' }
    let(:bucket) { 'foo' }
    let(:region) { 'bar' }

    before do
      allow(S3).to receive(:put)
      allow(Syndication::Product).to receive(:where).and_return products
      allow(Maisonette::Config).to receive(:fetch).with('aws.syndication_bucket').and_return bucket
      allow(Maisonette::Config).to receive(:fetch).with('aws.region').and_return region

      allow(worker).to receive(:klaviyo_product).with(product1).and_return product1.attributes
      allow(worker).to receive(:klaviyo_product).with(product2).and_return product2.attributes

      allow(described_class)
      worker.perform
    end

    it 'collects the syndication products' do
      expect(Syndication::Product).to have_received(:where).with(is_product: true)
      expect(worker).to have_received(:klaviyo_product).twice
    end

    it 'puts the collection to s3' do
      expect(S3).to have_received(:put).with(url, payload, bucket: bucket, region: region, acl: 'public-read')
    end
  end

  describe '#combined_categories' do
    subject(:categories) { worker.send(:combined_categories, product) }

    let(:product) do
      create :syndication_product,
             :for_product,
             gender: gender,
             trends: trends,
             age_range: age_range,
             category: category,
             product_type: product_type
    end

    let(:gender) { %w[Girl Unisex] }
    let(:trends) { ['Selling Fast This Week', 'Selling Fast'] }
    let(:age_range) { %w[0-2m 2-4m] }
    let(:category) { ['Dresses', 'Girl > Dresses'] }
    let(:product_type) { ['Dresses'] }

    it { is_expected.to be_a Array }

    it 'maps the categories correctly' do
      is_expected.to match_array(
        ['Gender: Girl', 'Gender: Unisex',
         'Trend: Selling Fast', 'Trend: Selling Fast This Week',
         'Age Range: 0-2m', 'Age Range: 2-4m',
         'Category: Dresses', 'Category: Girl > Dresses',
         'Product Type: Dresses']
      )
    end
  end
end
