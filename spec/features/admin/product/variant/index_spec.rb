# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Product Variants Index Page', type: :feature do
  stub_authorization!

  let(:index_page) { Admin::Products::Variants::IndexPage.new }

  describe 'actions' do
    let(:product) { create :product, option_types: [option_type] }
    let(:option_type) { create :option_type, option_values: [option_value] }
    let(:option_value) { create :option_value }
    let!(:offer_settings_1) { create :offer_settings, variant: variant_1 }
    let(:variant_1) { create :variant, product: product, option_values: [option_value] }
    let!(:offer_settings_2) { create :offer_settings, variant: variant_2 }
    let!(:variant_2) { create :variant, product: product, option_values: [option_value] }

    before do
      allow(Mirakl::ProcessOffersOrganizer).to receive(:call)

      index_page.load(slug: product.slug)
      index_page.reprocess_mirakl_offers_btn.click
    end

    it 'can reprocess the mirakl offers for the variants' do
      expect(Mirakl::ProcessOffersOrganizer).to have_received(:call).with(skus: [offer_settings_1.maisonette_sku,
                                                                                 offer_settings_2.maisonette_sku])
    end
  end
end
