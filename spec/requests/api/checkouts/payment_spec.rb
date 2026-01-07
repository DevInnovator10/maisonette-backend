# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/checkouts/', type: :request do
  let(:headers) { { 'X-Spree-Order-Token' => order.guest_token } }

  describe '#update' do
    let(:order) { create(:order_ready_to_complete, state: state) }

    context 'when user add a line item' do
      let(:state) { 'confirm' }
      let(:variant) { create(:variant, :with_multiple_prices) }
      let(:vendor) { variant.prices.second.vendor }
      let(:stock_location) { create(:stock_location, propagate_all_variants: true, vendor: vendor) }

      before do
        stock_location
        create(:stock_location, propagate_all_variants: true)
        Spree::StockItem.all.each { |si| si.set_count_on_hand(100) }
      end

      it 'recalculates the payments' do
        post "/api/orders/#{order.number}/line_items",
             headers: headers,
             params: { line_item: { variant_id: variant.id,
                                    quantity: 1,
                                    options: { vendor_id: vendor.id } } }

        put "/api/checkouts/#{order.number}", headers: headers

        put "/api/checkouts/#{order.number}", headers: headers

        expect(
          json_response['payments'].last['amount']
        ).to eq json_response['total']
      end
    end

    context 'when user applies coupon after payment' do
      let(:state) { 'payment' }
      let(:promo_code) { create(:promotion_code, gift_card: gift_card_with_credit, value: 'egift-credit') }
      let(:gift_category) { create(:promotion_category, name: 'E-Gift Card', gift_card: true) }
      let(:gift_card_with_credit) { create(:spree_gift_card, original_amount: 5) }
      let(:gift_card_promo) do
        create(
          :promotion,

          :with_gift_card_transaction,
          codes: [promo_code],
          promotion_category_id: gift_category.id
        )
      end

      before { gift_card_promo }

      it 'recalculates the payments' do
        post "/api/orders/#{order.number}/coupon_codes",
             headers: headers,
             params: { coupon_code: promo_code.value }

        put "/api/checkouts/#{order.number}", headers: headers

        expect(
          json_response['payments'].last['amount']
        ).to eq json_response['total']
      end
    end

    context 'when the user is anonymous' do
      let(:order) { create(:order_ready_to_complete, state: state, user: nil, email: 'user@example.com') }

      context 'when user applies coupon after payment' do
        let(:state) { 'payment' }
        let(:promo_code) { create(:promotion_code, gift_card: gift_card_with_credit, value: 'egift-credit') }
        let(:gift_category) { create(:promotion_category, name: 'E-Gift Card', gift_card: true) }
        let(:gift_card_with_credit) { create(:spree_gift_card, original_amount: 5) }
        let(:gift_card_promo) do
          create(
            :promotion,
            :with_gift_card_transaction,
            codes: [promo_code],
            promotion_category_id: gift_category.id
          )
        end

        before { gift_card_promo }

        it 'recalculates the payments' do
          post "/api/orders/#{order.number}/coupon_codes",
               headers: headers,
               params: { coupon_code: promo_code.value }

          put "/api/checkouts/#{order.number}", headers: headers

          expect(
            json_response['payments'].last['amount']
          ).to eq json_response['total']
        end
      end
    end
  end
end
