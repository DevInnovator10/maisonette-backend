# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Filtering Orders', type: :feature do
  stub_authorization!

  let(:load_orders_page) { orders_page.load }
  let(:orders_page) { Admin::Orders::IndexPage.new }
  let(:order1) { create :completed_order_with_totals }
  let(:order2) { create :completed_order_with_totals }

  describe 'when filtering orders from the index page' do
    before do
      order1 && order2
      load_orders_page
    end

    it 'can see the order id input' do
      expect(orders_page).to have_order_id_input
    end

    it 'can search by order id' do
      expect(orders_page).to have_content order1.number
      expect(orders_page).to have_content order2.number

      orders_page.order_id_input.fill_in with: order2.id
      orders_page.filter_button.click

      expect(orders_page).to have_content order2.number
      expect(orders_page).not_to have_content order1.number
    end
  end
end
