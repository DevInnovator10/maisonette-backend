# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Order', :js, type: :feature do
    include Feature::OrderFeatureHelper

  stub_authorization!

  context 'when creating a new order' do
    let(:default_location) { create(:stock_location) }
    let(:cool_location) { create(:stock_location, name: 'Cool location') }
    let(:another_location) { create(:stock_location, name: 'Another location') }
    let(:product) { variant.product }
    let(:cart_page) { Admin::Orders::Edit::CartPage.new }
    let(:order) { create(:order) }
    let(:default_vendor) { create(:vendor, :default, stock_location: default_location) }
    let(:cool_vendor) { create(:vendor, stock_location: cool_location, name: 'cool') }
    let(:another_vendor) { create(:vendor, stock_location: another_location, name: 'another vendor') }
    let(:variant) { create :variant }
    let(:master_variant) { product.master }

    before do
      variant.prices << create(:price, amount: 10.0, vendor: default_vendor)
      variant.prices << create(:price, amount: 14.0, vendor: cool_vendor)
      variant.stock_items << create(:stock_item, stock_location: default_vendor.stock_location)
      variant.stock_items << create(:stock_item, stock_location: cool_vendor.stock_location)
      master_variant.prices << create(:price, amount: 12.0, vendor: default_vendor)
      master_variant.stock_items << create(:stock_item, stock_location: default_vendor.stock_location)
    end

    context 'with in stock line_items' do
      before { cart_page.load(id: order.number) }

      context 'when an order is complete' do
        let(:order) { create :order, state: :complete }

        it 'does not render the add line item button' do
          expect(cart_page).not_to have_add_line_item_button
        end
      end

      it 'renders the add line item button' do
        expect(cart_page).to have_add_line_item_button
      end

      it 'can add and edit a line item' do
        skip('flaky https://github.com/MaisonetteWorld/maisonette-backend/issues/1156')
        expect(cart_page).to be_displayed

        cart_page.select_vendor(default_vendor.name)

        add_line_item(product.name, quantity: 1)

        expect(cart_page.line_item_vendor).to have_content(default_vendor.name)

        cart_page.update_line_item(cool_vendor.name)

        expect(cart_page.line_item_vendor).to have_content(cool_vendor.name)
      end

      it 'shows only available vendors' do
        expect(cart_page).to be_displayed

        cart_page.select_variant(variant.sku)
        cart_page.vendor_selector.click

        cart_page.vendor_selector.fill_in with: default_vendor.name
        expect(cart_page.results).to have_content(default_vendor.name)

        cart_page.vendor_selector.fill_in with: another_vendor.name
        expect(cart_page.results).not_to have_content(another_vendor.name)
      end

      it 'shows only non-master variants' do
        expect(cart_page).to be_displayed

        cart_page.variant_selector.click
        cart_page.search.fill_in with: master_variant.sku
        cart_page.wait_until_waiting_results_invisible

        expect(cart_page.results).not_to have_content(master_variant.sku)
      end
    end

    context 'when there are oos line items' do
      let!(:offer_settings) do
        create(:offer_settings, variant: variant, vendor: line_item.vendor)
      end
      let(:order) { create(:order_with_line_items) }
      let(:variant) { order.variants.last }
      let(:line_item) { order.line_items.last }

      before do
        variant.stock_items.each do |si|
          si.set_count_on_hand(0)
          si.update(backorderable: false)
        end
        cart_page.load(id: order.number)
      end

      it 'shows oos line items in the order summary' do
        expect(cart_page).to be_displayed

        expect(cart_page).to have_oos_status_label
        expect(cart_page.has_oos_status_value?(text: offer_settings.vendor_sku)).to be true
      end
    end
  end
end
