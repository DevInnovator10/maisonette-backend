# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::SaleSkuConfigurationPresenter do
  describe '#call' do
    subject { described_class.new(sale).call }

    let(:sale) { create(:sale) }

    context 'when no sales configurations present' do
      it 'generates empty array' do
        is_expected.to eq([])
      end
    end

    context 'when sales configurations present' do
      before do
        create(:sale_sku_configuration, sale: sale, percent_off: 0.3)
      end

      let(:configuration) { sale.sale_sku_configurations.first }

      it 'takes the sale and generates the information for sku configurations' do
        is_expected.to match array_including(
          hash_including(
            product_name: configuration.offer_settings.variant.product.name,
            vendor_name: configuration.offer_settings.vendor.name,
            maisonette_sku: configuration.offer_settings.maisonette_sku,
            vendor_sku: configuration.offer_settings.vendor_sku,
            percent_off: (configuration.percent_off.to_f * 100),
            maisonette_liability: configuration.maisonette_liability,
            final_sale: configuration.final_sale,
            start_date: configuration.start_date,
            end_date: configuration.end_date
          )
        )
      end
    end
  end
end
