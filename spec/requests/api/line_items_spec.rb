# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'LineItems API', type: :request do
  let(:guest_order_token) { { 'X-Spree-Order-Token' => order.guest_token } }
  let(:variant) { create :variant, prices: [price], stock_items: [stock_item] }
  let(:price) { create :price, vendor: vendor }
  let(:stock_item) { create :stock_item, stock_location: stock_location, backorderable: false }
  let(:vendor) { create :vendor, stock_location: stock_location }
  let(:order) { create(:order) }
  let(:stock_location) { create :stock_location }

  let(:do_request) do
    post "/api/orders/#{order.number}/line_items",
         headers: guest_order_token,
         params: { line_item: { variant_id: variant.id,
                                quantity: 1,
                                options: { vendor_id: vendor.id } } }
  end

  context 'when creating a line item' do
    it 'returns required vendor attributes in json response' do
      do_request
      expect(response).to have_http_status(:created)
      expect(json_response['vendor_id']).to eq vendor.id
      expect(json_response['country_iso']).to eq vendor.country_iso
      expect(json_response['domestic_override']).to eq vendor.domestic_override
    end

    it 'returns the variant lead time' do
      do_request
      expect(json_response['variant']).to have_attributes %w[lead_time]
    end

    it 'returns the required attributes' do
      do_request
      have_attributes %w[
        single_display_amount display_amount total final_sale on_sale backordered
        promotionable variant original_price sale_price
      ]
    end

    context 'when exception is not from line item' do
      let(:exception) { StandardError.new 'foo' }

      before { allow(Spree::OrderUpdater).to receive(:new).and_raise(exception) }

      it 'raises error' do
        expect { do_request }.not_to raise_error(exception)

        expect(json_response[:error]).to eq 'foo'
      end
    end

    context 'with no price for selected vendor' do
      let(:do_request) do
        post "/api/orders/#{order.number}/line_items",
             headers: guest_order_token,
             params: { line_item: { variant_id: variant.id,
                                    quantity: 1,
                                    options: { vendor_id: vendor_no_prices.id } } }
      end
      let(:vendor_no_prices) { create(:vendor, prices: []) }

      it 'returns an error' do
        do_request

        expect(json_response[:error]).to be_present
      end
    end
  end
end
