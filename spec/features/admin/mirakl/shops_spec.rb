# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mirakl Shops', :js, type: :feature do
  stub_authorization!

  let(:index_page) { Admin::Mirakl::Shops::IndexPage.new }

  it 'shows the Mirakl Shops page' do
    index_page.load
    expect(index_page.content_header.breadcrumb.text).to eq("Mirakl\nShops")
  end

  context 'when there are products in stock and out of stock' do
    let!(:mirakl_shop) { create(:mirakl_shop, :with_stock_location) }

    it 'shows a mirakl shop' do
      index_page.load
      expect(index_page).to have_content(mirakl_shop.name)
    end
  end

  describe 'filters' do
    let!(:mirakl_shop_1) { create(:mirakl_shop, :with_stock_location) }
    let!(:mirakl_shop_2) { create(:mirakl_shop, :with_stock_location) }

    before { index_page.load }

    context 'when filtering by shop name' do
      before do
        index_page.name_filter.set mirakl_shop_1.name
        index_page.filter_button.click
      end

      it 'shows the mirakl shop matching the name' do
        expect(index_page).to have_content(mirakl_shop_1.name)
        expect(index_page).not_to have_content(mirakl_shop_2.name)
      end
    end

    context 'when filtering by shop number' do
      before do
        index_page.shop_number_filter.set mirakl_shop_1.shop_id
        index_page.filter_button.click
      end

      it 'shows the mirakl shop matching the number' do
        expect(index_page).to have_content(mirakl_shop_1.name)
        expect(index_page).not_to have_content(mirakl_shop_2.name)
      end
    end

    context 'when filtering by shop id' do
      before do
        index_page.shop_id_filter.set mirakl_shop_1.id
        index_page.filter_button.click
      end

      it 'shows the mirakl shop matching the id' do
        expect(index_page).to have_content(mirakl_shop_1.name)
        expect(index_page).not_to have_content(mirakl_shop_2.name)
      end
    end
  end

  describe 'actions' do
    describe 'Import Shops From Mirakl' do
      before do
        allow(Mirakl::ImportShopsInteractor).to receive(:call)

        index_page.load
        index_page.mirakl_shop_delta_sync_btn.click
      end

      it 'calls Mirakl::ImportShopsInteractor.call and redirects back' do
        expect(Mirakl::ImportShopsInteractor).to have_received(:call)
        expect(index_page.content_header.breadcrumb.text).to eq("Mirakl\nShops")
      end
    end
  end
end
