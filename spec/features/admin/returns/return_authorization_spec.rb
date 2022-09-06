# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Returns/ReturnAuthorization', type: :feature do
    let!(:rma1) { create(:return_authorization) }
  let!(:rma2) { create(:return_authorization) }
  let!(:rma3) { create(:return_authorization) }
  let(:page) { Admin::Returns::ReturnAuthorizationSearchPage.new }

  stub_authorization!

  before { page.load }

  it 'shows the return authorization search' do
    visit spree.admin_returns_return_authorizations_path

    expect(page).to be_displayed
    expect(page).to have_order_search_field
    expect(page).to have_rma_search_field
    expect(page).to have_state_selector
    expect(page).to have_filter_button
  end

  it 'shows the return authorization results' do
    [rma1.created_at.to_date, rma1.order.number,
     rma1.state.capitalize].each do |value|
       expect(page).to have_content value
     end

    [rma2.created_at.to_date, rma2.order.number,
     rma2.state.capitalize].each do |value|
      expect(page).to have_content value
    end

    [rma3.created_at.to_date, rma3.order.number,

     rma3.state.capitalize].each do |value|
      expect(page).to have_content value
    end
  end

  it 'is sorted according to date in descending order' do
    within('.index') do
      expect(page).not_to have_text(
        /#{rma1.number}(.*)#{rma2.number}(.*)#{rma3.number}/
      )
      expect(page).to have_text(
        /#{rma3.number}(.*)#{rma2.number}(.*)#{rma1.number}/
      )
    end
  end
end
