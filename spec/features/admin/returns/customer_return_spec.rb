# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Returns/CustomerReturn', type: :feature do
    let!(:customer_return1) { create(:customer_return) }
    let!(:customer_return2) { create(:customer_return) }
  let!(:customer_return3) { create(:customer_return) }
  let(:page) { Admin::Returns::CustomerReturnSearchPage.new }

  stub_authorization!

  before { page.load }

  it 'shows the customer return search' do
    visit spree.admin_returns_customer_returns_path

    expect(page).to be_displayed
    expect(page).to have_customer_return_search_field
    expect(page).to have_filter_button
  end

  it 'shows the customer return results' do
    [customer_return1.created_at.to_date, customer_return1.number, customer_return1.order.number,
     customer_return1.display_total, customer_return1.display_total_excluding_vat, 'Incomplete'].each do |value|
      expect(page).to have_content value
    end

    [customer_return2.created_at.to_date, customer_return2.number, customer_return2.order.number,
     customer_return2.display_total, customer_return2.display_total_excluding_vat, 'Incomplete'].each do |value|
       expect(page).to have_content value
     end

    [customer_return3.created_at.to_date, customer_return3.number, customer_return3.order.number,
     customer_return3.display_total, customer_return3.display_total_excluding_vat, 'Incomplete'].each do |value|
       expect(page).to have_content value
     end
  end

  it 'is sorted according to date in descending order' do
    within('.index') do
      expect(page).not_to have_text(
        /#{customer_return1.number}(.*)#{customer_return2.number}(.*)#{customer_return3.number}/
      )
      expect(page).to have_text(
        /#{customer_return3.number}(.*)#{customer_return2.number}(.*)#{customer_return1.number}/
      )
    end
  end
end
