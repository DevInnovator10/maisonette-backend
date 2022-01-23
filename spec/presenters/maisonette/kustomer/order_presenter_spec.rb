# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Kustomer::OrderPresenter do
  describe '#kustomer_payload' do
    subject { described_class.new(order).kustomer_payload }

    let(:stock_location) { create(:stock_location, propagate_all_variants: true) }
    let(:first_vendor) { create(:vendor, stock_location: stock_location) }
    let(:vendor_prices) { [{ vendor: first_vendor, amount: 10 }] }
    let(:offer_settings) { [create(:offer_settings, vendor_id: first_vendor.id, cost_price: 15)] }
    let(:variant) do
      create(
        :variant,
        :with_multiple_prices,
        vendor_prices: vendor_prices,
        offer_settings: offer_settings
      ).tap do |variant|
        variant.stock_items.first.set_count_on_hand(10)
      end
    end
    let(:order) do
      create(
        :order_ready_to_ship,
        stock_location: stock_location,
        payment_type: :jifiti_payment,
        line_items_attributes: [{
          price: variant.price_for_vendor(first_vendor, as_money: false).amount,
          vendor: first_vendor,
          variant: variant
        }]
      )
    end

    it do
      is_expected.to match hash_including(
        orderNumber: order.number,
        email: order.email,
        shipments: array_including(hash_including(:shipmentNumber)),
        lineItemDetails: array_including(hash_including(:shipmentNumber)),
        paymentDetails: array_including(
          hash_including(name: 'Jifiti')
        ),
        billingAddress: hash_including(:address, :city, :zipcode, :state, :country),
        shippingAddress: hash_including(:address, :city, :zipcode, :state, :country)
      )
    end

    context 'when the shipping address or billing address are nil, and the order is legacy_order' do
      before do
        allow(order).to receive(:billing_address).and_return(nil)
        allow(order).to receive(:shipping_address).and_return(nil)
        allow(order).to receive(:legacy_order?).and_return(true)
      end

      it do
        is_expected.to match hash_including(
          billingAddress: nil,
          shippingAddress: nil
        )
      end
    end

    context 'with reimbursements' do
      subject { described_class.new(order).kustomer_payload }

      let(:reimbursement_gift_card) { create(:reimbursement_gift_card, reimbursement: reimbursement) }
      let(:reimbursement) { create(:reimbursement, customer_return: customer_return) }
      let(:customer_return) { create(:customer_return_with_accepted_items, line_items_count: 1, shipped_order: order) }
      let(:order) do
        create(
          :shipped_order,
          stock_location: stock_location,
          payment_type: :jifiti_payment,
          line_items_attributes: [{
            price: variant.price_for_vendor(first_vendor, as_money: false).amount,
            vendor: first_vendor,
            variant: variant
          }]
        )
      end
      let(:return_authorization) { order.return_authorizations.first }
      let(:return_item) { return_authorization.return_items.first }
      let(:refund) { create(:refund, reimbursement: reimbursement) }
      let(:reimbursement_store_credit) do
        create(:reimbursement_credit, reimbursement: reimbursement, creditable: store_credit)
      end
      let(:store_credit) { create(:store_credit) }

      before do
        reimbursement_gift_card
        reimbursement_store_credit
        refund
      end

      it 'includes reimbursements, returnItems, returnAuthorization' do
        is_expected.to match hash_including(
          orderNumber: order.number,
          returnAuthorizations: array_including(hash_including('number' => return_authorization.number)),
          returnItems: array_including(
            hash_including('returnAuthorizationNumber' => return_item.return_authorization.number)
          )
        )
      end

      it 'includes reimbursements and refunds' do
        is_expected.to match hash_including(
          orderNumber: order.number,
          reimbursements: array_including(hash_including('number' => reimbursement.number)),
          refunds: array_including(
            hash_including('amount' => refund.amount, 'reimbursementNumber' => refund.reimbursement.number)
          )
        )
      end

      it 'includes reimbursements and credits' do
        is_expected.to match hash_including(
          orderNumber: order.number,
          reimbursements: array_including(hash_including('number' => reimbursement.number)),
          credits: array_including(
            hash_including(
              'reimbursementNumber' => reimbursement_store_credit.reimbursement.number,
              'type' => 'Spree::StoreCredit'
            ),
            hash_including(
              'reimbursementNumber' => reimbursement_gift_card.reimbursement.number,
              'type' => 'Spree::PromotionCode'
            )
          )
        )
      end
    end

    context 'when offer settings is not present' do
      let(:offer_settings) { [] }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { described_class.new(order).kustomer_payload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'when there is an offer settings with matching maisonette_sku' do
        let(:other_offer_settings) { create(:offer_settings, vendor_id: first_vendor.id, maisonette_sku: variant.sku) }

        before do
          other_offer_settings
        end

        it 'return maisonette_sku from offer_settings' do
          is_expected.to match hash_including(
            orderNumber: order.number,
            lineItemDetails: array_including(
              hash_including(
                maisonetteSku: other_offer_settings.maisonette_sku,
                vendorSku: other_offer_settings.vendor_sku
              )
            )
          )
        end
      end
    end

    context 'when payment method is Braintree', :vcr do
      let(:order) do
        create(
          :order_ready_to_ship,
          stock_location: stock_location,
          payment_type: :solidus_paypal_braintree_credit_card_payment,
          line_items_attributes: [{
            price: variant.price_for_vendor(first_vendor, as_money: false).amount,
            vendor: first_vendor,
            variant: variant
          }]
        )
      end

      it 'returns payment details with Braintree payment method name' do
        is_expected.to match hash_including(
          orderNumber: order.number,
          email: order.email,
          shipments: array_including(hash_including(:shipmentNumber)),
          lineItemDetails: array_including(hash_including(:shipmentNumber)),
          paymentDetails: array_including(
            hash_including(name: 'Braintree::CreditCard')
          )
        )
      end
    end

    context 'when the line item is not part of the completed order' do
      before do
        allow(order.line_items[0]).to receive(:inventory_units).and_return([])
      end

      it do
        is_expected.to match hash_including(lineItemDetails: [])
      end
    end
  end
end
