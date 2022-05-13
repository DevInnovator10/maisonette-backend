# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gift Card Edit Page', :js, type: :feature do
  stub_authorization!

  let(:order) { create(:order) }
  let(:line_item) { create(:line_item, order: order, price: 50) }
  let(:gift_card) { create(:spree_gift_card, line_item: line_item, name: 'Initial Name') }
  let(:edit_page) { Admin::GiftCard::EditPage.new }
  let(:order_show_page) { Admin::Orders::Edit::ShipmentsPage.new }

  context 'when user visits the gift card edit page' do
    it 'is able to edit the gift card' do
      edit_page.load(id: gift_card.id)
      expect(edit_page).to be_displayed

      form = edit_page.form
      form.name_field.set 'Gift Card Name'

      form.form_actions.submit.click

      expect(edit_page).to be_displayed
      expect(edit_page).to have_content('Gift card "Gift Card Name" has been successfully updated!')
      expect(gift_card.reload.name).to eq 'Gift Card Name'
    end

    it 'is able to cancel out of edit page' do
      edit_page.load(id: gift_card.id)
      expect(edit_page).to be_displayed

      form = edit_page.form
      form.form_actions.cancel.click

      expect(order_show_page).to be_displayed
    end
  end
end
