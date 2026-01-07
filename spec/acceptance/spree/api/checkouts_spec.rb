# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.resource 'Checkout', type: :acceptance do
  header 'Accept', 'application/json'
  header 'X-Spree-Order-Token', :guest_order_token

  before do
    stub_authentication!
  end

  let(:id) { order.number }
  let(:guest_order_token) { order.guest_token }

  patch '/api/checkouts/:id' do
    parameter :id, 'The order number', required: true

    parameter :payment_attributes,
              'The payment attributes',
              type: :array,
              items: { type: :object },
              scope: :order,
              required: true
    parameter :payment_method_id, 'The payment method id', scope: [:order, :payment_attributes], required: true

    let(:order) { create(:order_ready_for_payment) }
    let(:payment_method) { create(:solidus_paypal_braintree_gateway) }

    context 'when the channel attribute is not set to default value' do
      parameter :channel, 'Specify the channel where the request is coming from', scope: :order

      let(:channel) { 'ios' }

      example_request 'Add an item to a cart' do
        expect(status).to eq 200
        expect(json_response['channel']).to eq('ios')
      end
    end

    context 'when a not yet existing Braintree payment is submitted' do
      parameter :nonce, 'The payment nonce', scope: [:order, :payment_attributes, :source_attributes], required: true

      context 'when the payment type is credit card' do
        parameter :payment_type,
                  "The payment type. Must be `#{SolidusPaypalBraintree::Source::CREDIT_CARD}`",
                  scope: [:order, :payment_attributes, :source_attributes],
                  required: true

        let(:payment_attributes) do
          [
            {
              payment_method_id: payment_method.id,
              source_attributes: {
                nonce: Braintree::Test::Nonce::TransactableVisa,
                payment_type: SolidusPaypalBraintree::Source::CREDIT_CARD,
                reusable: true
              }
            }
          ]
        end

        example_request 'Processing the checkout payment step with a not yet existing credit card payment' do
          expect(status).to eq 200
        end
      end

      context 'when the payment type is PayPal' do
        parameter :payment_type,
                  "The payment type. Must be `#{SolidusPaypalBraintree::Source::PAYPAL}`",
                  scope: [:order, :payment_attributes, :source_attributes],
                  required: true

        let(:payment_attributes) do
          [
            {
              payment_method_id: payment_method.id,
              source_attributes: {
                nonce: Braintree::Test::Nonce::PayPalBillingAgreement,
                payment_type: SolidusPaypalBraintree::Source::PAYPAL,
                reusable: true
              }
            }
          ]
        end

        example_request 'Processing the checkout payment step with a not yet existing PayPal payment' do
          expect(status).to eq 200
        end
      end

      context 'when the payment type is ApplePay' do
        parameter :payment_type,
                  "The payment type. Must be `#{SolidusPaypalBraintree::Source::APPLE_PAY}`",
                  scope: [:order, :payment_attributes, :source_attributes],
                  required: true

        let(:payment_attributes) do
          [
            {
              payment_method_id: payment_method.id,
              source_attributes: {
                nonce: Braintree::Test::Nonce::ApplePayVisa,
                payment_type: SolidusPaypalBraintree::Source::APPLE_PAY,
                reusable: true
              }
            }
          ]
        end

        example_request 'Processing the checkout payment step with a not yet existing ApplePay payment' do
          expect(status).to eq 200
        end
      end
    end

    context 'when an existing valid Braintree payment is submitted' do
      parameter :wallet_payment_source_id,
                'The payment source id of a payment within the user’s payments wallet',
                scope: [:order, :payment_attributes, :source_attributes],
                required: true

      context 'when the payment type is credit card' do
        let(:order) { create(:order_ready_for_payment) }
        let(:solidus_paypal_braintree_source) do
          create :solidus_paypal_braintree_source,
                 :transactable_visa,
                 payment_method: payment_method,
                 user: order.user
        end
        let(:wallet_payment_source) { order.user.wallet.add solidus_paypal_braintree_source }
        let(:payment_attributes) do
          [
            {
              payment_method_id: payment_method.id
            },
            source_attributes: {
              wallet_payment_source_id: wallet_payment_source.id
            }
          ]
        end

        example_request 'Processing the checkout payment step with an already existing payment' do
          expect(status).to eq 200
        end
      end
    end
  end

  put '/api/checkouts/:id/complete' do
    parameter :id, 'The order number', required: true
    parameter :expected_total, 'The amount the customer expects to pay'

    context 'when the order includes a Braintree payment', :vcr do
      let(:order) { create(:order_ready_to_complete, payment_type: :solidus_paypal_braintree_credit_card_payment) }
      let(:expected_total) { order.total }

      example_request 'Completing the checkout when the order includes a Braintree payment' do
        expect(status).to eq 200
      end
    end
  end

  put '/api/checkouts/:id' do
    parameter :id, 'The order number', required: true
    parameter :ship_address_attributes, required: true, scope: :order
    parameter :bill_address_attributes, scope: :order
    parameter :use_billing, 'when `true` set billing address equal to shipping', scope: :order
    parameter :hold_state, 'skip state transition'
    parameter :address_verification, 'validate shipping address and return modifications'

    context 'when updating the address' do
      let(:order) { create(:order_with_line_items, ship_address: nil, bill_address: nil) }
      let(:ship_address_attributes) { build(:address).attributes }
      let(:hold_state) { true }
      let(:use_billing) { true }

      example_request 'update address' do
        expect(status).to eq 200
      end
    end

    context 'when address_verification is true' do
      let(:order) { create :order_ready_to_complete, line_items_count: 1 }
      let(:address_verification) { true }

      # rubocop:disable RSpec/VerifiedDoubles
      let(:easypost_address) do
        double EasyPost::Address,
               street1: 'WASHINGTON ST',
               street2: '',
               city: 'BROOKLYN',
               state: 'WA',
               zip: '11201-1036',
               country: 'US',
               residential: true,
               verifications: easypost_verifications
      end
      let(:easypost_verifications) { double EasyPost::EasyPostObject, zip4: easypost_zip4 }
      let(:easypost_zip4) do
        double EasyPost::EasyPostObject,
               success: true,
               errors: [
                 easypost_error1,
                 easypost_error2
               ]
      end
      let(:easypost_error1) do
        double EasyPost::EasyPostObject, field: 'street1', message: 'House number missing', suggestion: nil
      end
      let(:easypost_error2) do
        double EasyPost::EasyPostObject, field: 'state', message: 'State does not match zipcode', suggestion: 'NY'
      end
      # rubocop:enable RSpec/VerifiedDoubles

      before do
        allow(Spree::Order).to receive(:find_by).and_return(order)
        allow(order.shipping_address).to receive(:to_easypost_address!).and_return(easypost_address)
      end

      example_request 'update address' do
        expect(json_response['address_verification']).to be_present
      end
    end
  end
end
