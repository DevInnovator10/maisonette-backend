# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mirakl Offers', :js, type: :feature do
  stub_authorization!

  let(:index_page) { Admin::Mirakl::Offers::IndexPage.new }
  let!(:mirakl_offer) { create(:mirakl_offer) }

  it 'shows the Mirakl Offers page' do
    index_page.load
    expect(index_page.content_header.breadcrumb.text).to eq("Mirakl\nOffers")
    expect(index_page).to have_content(mirakl_offer.sku)
  end

  describe 'filters' do
    let!(:mirakl_offer_1) { create(:mirakl_offer) }
    let!(:mirakl_offer_2) { create(:mirakl_offer) }

    before { index_page.load }

    context 'when filtering by offer sku' do
      before do
        index_page.sku_filter.set mirakl_offer_1.sku
        index_page.filter_button.click
      end

      it 'shows the mirakl offer matching the sku' do
        expect(index_page).to have_content(mirakl_offer_1.sku)
        expect(index_page).not_to have_content(mirakl_offer_2.sku)
      end
    end

    context 'when filtering by offer id' do
      before do
        index_page.offer_id_filter.set mirakl_offer_1.offer_id
        index_page.filter_button.click
      end

      it 'shows the mirakl offer matching the offer id' do
        expect(index_page).to have_content(mirakl_offer_1.offer_id)
        expect(index_page).not_to have_content(mirakl_offer_2.offer_id)
      end
    end

    context 'when filtering by shop' do
      before do
        index_page.shop_name_filter.select mirakl_offer_1.shop.name
        index_page.filter_button.click
      end

      it 'shows the mirakl offer matching the shop' do
        expect(index_page).to have_content(mirakl_offer_1.sku)
        expect(index_page).not_to have_content(mirakl_offer_2.sku)
      end
    end
  end

  describe 'actions' do
    describe 'Delta Import Offers From Mirakl' do
      let(:entered_datetime) { '2019/09/04 05:27 PM' }

      before do
        allow(Mirakl::ImportOffersWorker).to receive_messages(perform_async: true)

        index_page.load
        index_page.delta_datetime_textfield.set entered_datetime
        index_page.mirakl_offers_delta_sync_btn.click
      end

      it 'calls Mirakl::ImportOffersWorker.perform_async and redirects back' do
        expect(Mirakl::ImportOffersWorker).to have_received(:perform_async).with(entered_datetime)
        expect(index_page.content_header.breadcrumb.text).to eq("Mirakl\nOffers")
      end
    end

    describe 'Full Import Offers From Mirakl' do
      before do
        allow(Mirakl::ImportOffersWorker).to receive_messages(perform_async: true)

        index_page.load
        index_page.mirakl_offers_full_sync_btn.click
      end

      it 'calls Mirakl::ImportOffersWorker.perform_async and redirects back' do
        expect(Mirakl::ImportOffersWorker).to have_received(:perform_async).with(nil)
        expect(index_page.content_header.breadcrumb.text).to eq("Mirakl\nOffers")
      end
    end
  end
end
