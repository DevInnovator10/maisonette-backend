# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Customer Details', type: :feature, js: true do
  stub_authorization!

  let(:country) { create(:country, name: 'Kangaland') }
  let(:state) { create(:state, name: 'Alabama', country: country) }
  let!(:order) { create(:order, ship_address: nil, bill_address: nil) }

  let!(:ship_address) { create(:address, country: country, state: state, first_name: 'Ship Address') }
  let!(:bill_address) { create(:address, country: country, state: state, first_name: 'Bill Address') }

  let!(:user) { create(:user, email: 'foobar@example.com', ship_address: ship_address, bill_address: bill_address) }

  let(:edit_page) { Admin::Orders::Edit::CustomerDetailsPage.new }

  before do
    edit_page.load(number: order.number)

    click_link 'Customer'

    targetted_select2 user.email, from: '#s2id_customer_search'
  end

  context 'when brand new order' do
    context 'when use shipping is selected' do
      it 'associates a user when not using guest checkout' do # rubocop:disable RSpec/MultipleExpectations
        expect(edit_page).to have_checked_field('order_use_billing')
        expect(edit_page).to have_field('First Name', with: user.ship_address.firstname)
        expect(edit_page).to have_field('Last Name', with: user.ship_address.lastname)
        expect(edit_page).to have_field('Street Address', with: user.ship_address.address1)
        expect(edit_page).to have_field("Street Address (cont'd)", with: user.ship_address.address2)
        expect(edit_page).to have_field('City', with: user.ship_address.city)
        expect(edit_page).to have_field('Zip Code', with: user.ship_address.zipcode)
        expect(edit_page).to have_select('Country', selected: 'United States of America', visible: false)
        expect(edit_page).to have_select('State', selected: user.ship_address.state.name, visible: false)
        expect(edit_page).to have_field('Phone', with: user.ship_address.phone)

        click_button 'Update'

        expect(order.reload.ship_address.first_name).to eq ship_address.first_name
        expect(order.reload.bill_address.first_name).to eq ship_address.first_name
      end
    end

    context 'when use shipping is not selected' do
      it 'associates a user when not using guest checkout' do # rubocop:disable RSpec/MultipleExpectations
        edit_page.use_billing.uncheck

        expect(edit_page).not_to have_checked_field('order_use_billing')

        edit_page.fill_in_billing_address(bill_address)

        expect(edit_page).to have_field('First Name', with: user.bill_address.firstname)
        expect(edit_page).to have_field('Last Name', with: user.bill_address.lastname)
        expect(edit_page).to have_field('Street Address', with: user.bill_address.address1)
        expect(edit_page).to have_field("Street Address (cont'd)", with: user.bill_address.address2)
        expect(edit_page).to have_field('City', with: user.bill_address.city)
        expect(edit_page).to have_field('Zip Code', with: user.bill_address.zipcode)
        expect(edit_page).to have_select('Country', selected: 'United States of America', visible: false)
        expect(edit_page).to have_select('State', selected: user.bill_address.state.name, visible: false)
        expect(edit_page).to have_field('Phone', with: user.bill_address.phone)

        click_button 'Update'

        expect(order.reload.ship_address.first_name).to eq ship_address.first_name
        expect(order.reload.bill_address.first_name).to eq bill_address.first_name
      end
    end
  end

  context 'when order has out of stock item' do
    let(:order) { create(:order_with_line_items, state: 'address') }
    let(:error_message) do
      display_name = order.variants.first.name.to_s
      display_name += " (#{order.variants.first.options_text})"
      I18n.t(
        'spree.selected_quantity_not_available',
        item: display_name.inspect
      )
    end

    before do
      Spree::StockItem.all.each do |si|
        si.set_count_on_hand(0)
        si.update(backorderable: false)
      end
    end

    it 'returns detailed inventory error' do
      click_button 'Update'

      expect(edit_page).to have_content(error_message)
    end
  end
end
