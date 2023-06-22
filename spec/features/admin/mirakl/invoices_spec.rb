# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mirakl Offers', :js, type: :feature do
  stub_authorization!

  let(:index_page) { Admin::Mirakl::Invoices::IndexPage.new }
  let!(:invoice) { create(:mirakl_invoice) }

  it 'shows the Mirakl Offers page' do
    index_page.load
    expect(index_page.content_header.breadcrumb.text).to eq("Mirakl\nInvoices")
    expect(index_page).to have_content(invoice.invoice_id)
  end

  describe 'filters' do
    before { index_page.load }

    context 'when filtering by issued' do
      let!(:invoice_1) { create(:mirakl_invoice, issued: true) }
      let!(:invoice_2) { create(:mirakl_invoice, issued: false) }

      before do
        index_page.issued_filter.select 'True'
        index_page.filter_button.click
      end

      it 'shows the mirakl offer matching the sku' do
        expect(index_page).to have_content(invoice_1.invoice_id)
        expect(index_page).not_to have_content(invoice_2.invoice_id)
      end
    end
  end

  describe 'actions' do
    describe 'Issue all invoices' do
      before do
        allow(Mirakl::IssueInvoicesWorker).to receive_messages(perform_async: true)

        index_page.load
        index_page.accept_alert 'Are you sure?' do
          index_page.issue_all_invoices.click
        end
        index_page.wait_until_filter_button_visible
      end

      it 'calls Mirakl::IssueInvoicesWorker.perform_async and redirects back' do
        expect(Mirakl::IssueInvoicesWorker).to have_received(:perform_async)
        expect(index_page.content_header.breadcrumb.text).to eq("Mirakl\nInvoices")
      end
    end
  end
end
