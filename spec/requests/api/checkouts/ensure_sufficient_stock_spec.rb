# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/checkouts/', type: :request do
  describe 'PUT next' do
    context 'when order at confirm state has insufficient stock' do
      subject(:do_complete) { put spree.complete_api_checkout_path(order.to_param), headers: headers }

      let(:headers) { { 'X-Spree-Order-Token' => order.guest_token } }

      let(:line_item) { order.line_items.first }
      let(:first_vendor) { create(:vendor, stock_location: stock_location) }
      let(:second_vendor) { create(:vendor, stock_location: stock_location2) }
      let(:vendor_prices) { [{ vendor: first_vendor, amount: 10 }, { vendor: second_vendor, amount: 15 }] }
      let(:variant) do
        create(
          :variant,
          :with_multiple_prices,
          vendor_prices: vendor_prices
        ).tap do |variant|
          variant.stock_items.first.set_count_on_hand(0)
          variant.stock_items.update(backorderable: false)
        end
      end
      let(:stock_location) { create(:stock_location, propagate_all_variants: true) }
      let(:stock_location2) { create(:stock_location, propagate_all_variants: true) }
      let(:order) do
        create(
          :order_ready_to_complete,
          stock_location: stock_location,
          line_items_attributes: [{
            price: variant.price_for_vendor(second_vendor, as_money: false).amount,
            vendor: second_vendor,
            variant: variant
          }]
        )
      end

      it 'brings back the order at payment level' do
        expect(order.reload.state).to eq('confirm')

        do_complete

        expect(json_response).to include(error: I18n.t(:insufficient_stock, scope: 'spree.api.order'))

        expect(order.reload.state).to eq('payment')
      end
    end
  end
end
