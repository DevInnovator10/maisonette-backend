# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing and Editing Shipments', type: :feature do
  stub_authorization!

  let(:shipments_page) { Admin::Orders::Edit::ShipmentsPage.new }
  let(:load_shipments_page) { shipments_page.load(number: line_item.order.number) }
  let(:order) { create :shipped_order }
  let(:line_item) { order.line_items.first }

  describe 'When viewing shipments' do
    before { load_shipments_page }

    it 'a user can see if a shipment price is final' do
      expect(line_item.final_sale?).to be false
      expect(shipments_page).not_to have_final_sale_div

      line_item.update!(final_sale: true)

      shipments_page.load(number: line_item.reload.order.number)
      expect(shipments_page).to have_final_sale_div
    end

    it "a user can see if a shipment's line_item is on sale" do
      line_item.update(price: 20, original_price: 20)
      expect(line_item.on_sale?).to be false
      load_shipments_page
      expect(shipments_page).not_to have_on_sale_div

      line_item.update(original_price: 30)
      expect(line_item.reload.on_sale?).to be true

      shipments_page.load(number: line_item.reload.order.number)
      expect(shipments_page).to have_on_sale_div
    end

    it 'a user can see sku link, lead time and customer eta' do
      expect(shipments_page).to have_shipment_customer_eta
      expect(shipments_page).to have_variant_sku_link
      expect(shipments_page).to have_variant_sku_link
    end

    it 'shows a link to customer summary view' do
      expect(shipments_page.summary_info).to have_customer_summary_link
    end

    it 'shows a link to narvar return' do
      expect(shipments_page.summary_info).to have_narvar_return_link
    end

    context 'when the order is a gift', :js do
      let(:email) { FFaker::Internet.email }
      let(:message) { FFaker::Lorem.sentence 2 }
      let(:order) { create :shipped_order, is_gift: true, gift_email: email, gift_message: message }

      it 'displays the gift section details if an order is a gift' do
        expect(shipments_page).to have_gift_section
        expect(shipments_page).to have_content email
        expect(shipments_page).to have_content message[0..11].strip
      end

      it 'displays the gift status in the sidebar' do
        expect(shipments_page).to have_gift_status_label
        expect(shipments_page.has_gift_status_value?(text: 'Yes')).to be true
      end
    end

    context 'when the order is not a gift' do
      let(:order) { create :shipped_order, is_gift: false }

      it 'display the gift section details anyway' do
        expect(shipments_page).to have_gift_section
      end

      it 'displays the gift status in the sidebar as "No"' do
        expect(shipments_page.has_gift_status_value?(text: 'No')).to be true
      end
    end
  end
end
