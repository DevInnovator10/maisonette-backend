# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Product Price Page', :js, type: :feature do
  stub_authorization!

  let(:index_page) { Admin::Products::Prices::IndexPage.new }
  let(:edit_page) { Admin::Products::Prices::EditPage.new }
  let(:slug) { variant.product.slug }

  context 'when visiting the price index page' do
    before do
      index_page.load
    end

    context 'with multiple vendor prices on master' do
      let(:variant) { create(:variant, :with_multiple_prices, :with_multiple_prices_on_master) }
      let(:vendor_from_master) { variant.product.master.prices.first.vendor }
      let(:vendor_from_variant) { variant.prices.first.vendor }

      it 'can filter master prices by vendor' do # rubocop:disable RSpec/MultipleExpectations
        visit spree.admin_product_prices_path(product_id: slug)

        expect(index_page).to be_displayed

        index_page.select_vendor(vendor_from_master.name)

        expect(index_page.variant_master_prices).to have_css('tr', count: 2)

        expect(index_page.variant_prices).to have_css('tr', count: 2)

        index_page.filter_button.click

        expect(index_page.variant_master_prices).to have_css('tr', count: 1)

        expect(index_page.variant_master_prices).to have_content(vendor_from_master.name)

        index_page.select_vendor(vendor_from_variant.name)

        index_page.filter_button.click

        expect(index_page.variant_prices).to have_css('tr', count: 1)

        expect(index_page.variant_prices).to have_content(vendor_from_variant.name)
      end
    end
  end

  context 'when creating a new price' do
    let(:product) { create(:product) }
    let(:slug) { product.slug }
    let(:vendor) { create(:vendor) }

    before do
      vendor.prices << create(:price, variant_id: product.master.id)
    end

    it 'can select a vendor for the price' do
      edit_page.load(id: slug)

      expect(edit_page).to be_displayed

      edit_page.select_vendor(vendor.name)

      edit_page.form_actions.submit.click

      expect(index_page).to be_displayed

      expect(index_page.variant_master_prices).to have_css('tr', count: 3)

      expect(index_page.variant_master_prices).to have_content(vendor.name)
    end
  end
end
