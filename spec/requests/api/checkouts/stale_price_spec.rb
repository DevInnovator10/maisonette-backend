# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/checkouts/', type: :request do
  describe 'PUT next' do
    context 'when order at confirm state has stale prices' do
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
          variant.stock_items.first.set_count_on_hand(10)
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

      before do
        price = order.variants.first.price_for_vendor(second_vendor, as_money: false)
        price.update(amount: 1)
      end

      it 'brings back the order at payment level' do
        expect { do_complete }.to change { order.reload.state }.from('confirm').to('payment')

        expect(json_response).to match hash_including('errors', error: I18n.t(:stale_price, scope: 'spree.api.order'))
        expect(order.payments.valid).to be_empty
      end
    end

    context 'when order at confirm state has stale payment' do
      subject(:do_complete) { put spree.complete_api_checkout_path(order.to_param), headers: headers }

      let(:headers) { { 'X-Spree-Order-Token' => order.guest_token } }

      let(:line_item) { order.line_items.first }
      let(:first_vendor) { create(:vendor, stock_location: stock_location) }
      let(:vendor_prices) { [{ vendor: first_vendor, amount: 10 }] }
      let(:variant) do
        create(
          :variant,
          :with_multiple_prices,
          vendor_prices: vendor_prices
        ).tap do |variant|
          variant.stock_items.first.set_count_on_hand(10)
        end
      end
      let(:stock_location) { create(:stock_location, propagate_all_variants: true) }
      let(:order) do
        create(
          :order_ready_to_complete,
          stock_location: stock_location,
          line_items_attributes: [{
            price: variant.price_for_vendor(first_vendor, as_money: false).amount,
            vendor: first_vendor,
            variant: variant
          }]
        )
      end

      before do
        payment = order.payments.last
        payment.update(amount: payment.amount - 1)
      end

      it 'brings back the order at payment level' do
        expect { do_complete }.to change { order.reload.state }.from('confirm').to('payment')

        expect(json_response).to match hash_including('errors', error: I18n.t(:stale_payment, scope: 'spree.api.order'))
        expect(order.payments.valid).to be_empty
      end
    end

    context 'when order has invalid line items variants out of stock' do
      let(:headers) { { 'X-Spree-Order-Token' => order.guest_token } }
      let(:stock_location) { create(:stock_location, propagate_all_variants: true) }
      let(:vendor) { create(:vendor, stock_location: stock_location) }
      let(:vendor_prices) { [{ vendor: vendor, amount: 10 }] }
      let(:variant) { create(:variant, :with_multiple_prices, vendor_prices: vendor_prices) }
      let(:order) do
        create(
          :order_with_line_items,
          stock_location: stock_location,

          line_items_attributes: [{
            price: variant.price_for_vendor(vendor, as_money: false).amount,
            vendor: vendor,
            variant: variant
          }]
        )
      end

      it 'returns an out of stock error' do
        variant = order.line_items.first.variant
        variant.prices = []
        variant.stock_items.first.set_count_on_hand(0)

        put spree.next_api_checkout_path(order.to_param), headers: headers

        expect(response.status).to eq 422
        expect(json_response).to match hash_including(
          'error',
          error: I18n.t('spree.checkout.errors.out_of_stock_items')
        )
      end
    end
  end
end
