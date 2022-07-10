# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Salsify Mirakl Offer Export Jobs', :js, type: :feature do
  stub_authorization!

  let(:index_page) { Admin::Salsify::MiraklOfferExportJobs::IndexPage.new }
  let!(:mirakl_offer_export_job) { create(:mirakl_offer_export_job) }

  it 'shows the Salsify Mirakl Offer Export Jobs page' do
    index_page.load
    expect(index_page.content_header.breadcrumb.text).to eq("Salsify\nMirakl Offer Export Jobs")
    expect(index_page).to have_content(mirakl_offer_export_job.id)
  end

  describe 'actions' do
    describe 'Pull Offers From Salsify To Mirakl' do
      let(:export_mirakl_offers_worker) { instance_double Salsify::ExportMiraklOffersWorker, perform: true }

      before do
        allow(Salsify::ExportMiraklOffersWorker).to receive_messages(new: export_mirakl_offers_worker)

        index_page.load
        index_page.pull_offers_from_salsify_to_mirakl_btn.click
      end

      it 'calls Salsify::ExportMiraklOffersWorker.new.perform and redirects back' do
        expect(export_mirakl_offers_worker).to have_received(:perform)
        expect(index_page.content_header.breadcrumb.text).to eq("Salsify\nMirakl Offer Export Jobs")
      end
    end

    describe 'Re-send offer file to Mirakl' do
      let(:export_mirakl_offers_worker) { instance_double Salsify::ExportMiraklOffersWorker, perform: true }

      before do
        allow(Salsify::MiraklOfferExportJob).to(
          receive(:find).with(mirakl_offer_export_job.id.to_s).and_return(mirakl_offer_export_job)
        )
        allow(mirakl_offer_export_job).to receive(:send_offers_to_mirakl)

        index_page.load

        index_page.accept_alert 'Are you sure?' do
          click_link 'Re-Send'
        end

        index_page.wait_until_pull_offers_from_salsify_to_mirakl_btn_visible
      end

      it 'calls send_offers_to_mirakl on the mirakl offer export job and redirects back' do
        expect(mirakl_offer_export_job).to have_received(:send_offers_to_mirakl)
        expect(index_page.content_header.breadcrumb.text).to eq("Salsify\nMirakl Offer Export Jobs")
      end
    end
  end
end
