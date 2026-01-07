# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::ExportOfferSettingsWorker do
  let(:worker) { described_class.new }

  it { expect(described_class).to be < ::Maisonette::BaseSaleExportWorker }

  describe '#collection' do
    subject(:collection) { worker.send(:collection) }

    let(:product1) { create(:product, name: 'Product') }
    let(:product2) { create(:product, name: 'Product') }
    let(:offer_settings1) { create(:offer_settings, variant: product1.master, maisonette_sku: 'MAISONETTE_SKU') }
    let(:offer_settings2) { create(:offer_settings, variant: product2.master, maisonette_sku: 'OTHER_SKU') }

    let(:search_query) do
      { 'product_name' => 'Product',
        'maisonette_sku_or_vendor_sku_or_variant_sku' => 'MAISONETTE_SKU' }
    end

    before do
      offer_settings1
      offer_settings2
      worker.instance_variable_set('@search_query', search_query)
    end

    it 'returns the correct offer settings collection' do
      expect(collection.map(&:id)).to eq [offer_settings1.id]
    end
  end

  describe '#csv_row_builder' do
    subject(:csv_row_builder) { worker.send(:csv_row_builder).call(offer_settings) }

    let(:product) { create(:product, name: 'Product') }
    let(:vendor) { create(:vendor, name: 'Vendor') }
    let(:offer_settings) do
      create(:offer_settings, variant: product.master, vendor: vendor,
                              maisonette_sku: 'MAISONETTE_SKU', vendor_sku: 'VENDOR_SKU')
    end
    let(:sale_sku) do
      create(:sale_sku_configuration, offer_settings: offer_settings, percent_off: 0.4,
                                      maisonette_liability: 50, start_date: Time.zone.now,
                                      static_sale_price: 15.45, static_cost_price: 10.34)
    end
    let(:sale) { create(:sale, sale_sku_configurations: [sale_sku]) }

    before { worker.instance_variable_set('@sale', sale) }

    context 'when the sale sku is added to the sale' do
      it 'returns the correct csv row', freeze_time: true do
        is_expected.to eq [
          'Product', 'Vendor', 'MAISONETTE_SKU', 'VENDOR_SKU', 40, 50, nil,
          Time.zone.now.strftime('%m-%d-%Y %I:%M %p'), nil, 15.45, 10.34, nil, true
        ]
      end
    end

    context 'when the sale sku is not added to the sale' do
      let(:sale) { create(:sale) }

      it 'returns the correct csv row' do
        is_expected.to eq [
          'Product', 'Vendor', 'MAISONETTE_SKU', 'VENDOR_SKU', nil, nil, nil, nil, nil, nil, nil, nil, false
        ]
      end
    end
  end

  describe '#csv_headers' do
    subject(:csv_headers) { worker.send(:csv_headers) }

    it 'returns the correct offer settings collection' do
      is_expected.to eq [
        'Product Name', 'Vendor Name', 'Maisonette SKU', 'Vendor SKU', 'Percent Off', 'Maisonette Liability',
        'Final Sale', 'Start Date', 'End Date', 'Sale Price', 'Cost Price', 'Remove from Sale', 'Added to Sale'
      ]
    end
  end
end
