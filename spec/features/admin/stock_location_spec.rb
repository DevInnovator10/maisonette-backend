# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Stock Location Page', :js, type: :feature do
  stub_authorization!

  let!(:vendor) { create(:vendor) }
  let(:index_page) { Admin::StockLocations::IndexPage.new }
  let(:edit_page) { Admin::StockLocations::EditPage.new }
  let(:new_page) { Admin::StockLocations::NewPage.new }
  let!(:stock_location) { create(:stock_location) }

  before do
    create(:country)
  end

  context 'when user visits the stock_location new page' do
    it 'is able to creates a new stock location' do
      new_page.load
      expect(new_page).to be_displayed

      form = new_page.form
      form.name_field.set 'Stock Location Name'
      form.select_vendor(vendor.name)

      form.form_actions.submit.click

      expect(index_page).to be_displayed
      expect(index_page).to have_content('Stock Location "Stock Location Name" has been successfully created!')
    end

    it 'is able to edit stock location' do
      edit_page.load(id: stock_location.id)

      expect(edit_page).to be_displayed

      form = edit_page.form
      form.name_field.set 'Stock Location Name'
      form.select_vendor(vendor.name)

      form.form_actions.submit.click

      expect(index_page).to be_displayed
      expect(index_page).to have_content('Stock Location "Stock Location Name" has been successfully updated!')
    end
  end

  describe 'Actions' do
    describe 'Re-create Fee Invoice Edit Page' do
      let(:mirakl_shop) { stock_location.mirakl_shop }

      before do
        allow(Mirakl::Invoices::ReSubmitFeesInvoiceInteractor).to receive(:call!)

        edit_page.load(id: stock_location.id)
        edit_page.accept_alert do
          edit_page.re_create_fee_invoice_btn.click
        end
        edit_page.wait_until_re_create_fee_invoice_btn_visible
      end

      it 'calls Mirakl::Invoices::ReSubmitFeesInvoiceInteractor with the mirakl shop' do
        expect(Mirakl::Invoices::ReSubmitFeesInvoiceInteractor).to have_received(:call!).with(mirakl_shop: mirakl_shop)
      end
    end

    describe 'Re-create Credit Invoice Edit Page' do
      let(:mirakl_shop) { stock_location.mirakl_shop }

      before do
        allow(Mirakl::Invoices::ReSubmitCreditsInvoiceInteractor).to receive(:call!)

        edit_page.load(id: stock_location.id)
        edit_page.accept_alert do
          edit_page.re_create_credit_invoice_btn.click
        end
        edit_page.wait_until_re_create_credit_invoice_btn_visible
      end

      it 'calls Mirakl::Invoices::ReSubmitCreditsInvoiceInteractor with the mirakl shop' do
        expect(Mirakl::Invoices::ReSubmitCreditsInvoiceInteractor).to have_received(:call!).with(mirakl_shop:
                                                                                                   mirakl_shop)
      end
    end
  end
end
