# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Returns/Refund', type: :feature do
  let!(:refund) do
    create(:refund, reimbursement: create(:reimbursement)).tap do |refund|
      refund.reimbursement.update(customer_return: nil)
    end
  end

  let(:page) { Admin::Returns::RefundSearchPage.new }

  stub_authorization!

  before { page.load }

  it 'shows the refund search' do
    visit spree.admin_returns_refunds_path

    expect(page).to be_displayed
    expect(page).to have_amount_search_field
    expect(page).to have_transaction_search_field
    expect(page).to have_filter_button
  end

  it 'shows the refund result' do
    [refund.created_at.to_date, refund.payment.order.number, refund.display_amount,
     refund.reason.name, refund.transaction_id].each do |value|
      expect(page).to have_content value
    end
  end
end
