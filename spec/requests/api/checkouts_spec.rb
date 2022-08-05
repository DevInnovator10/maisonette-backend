# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Checkouts API', type: :request do
  describe 'PATCH update' do
    context 'when updating an address' do
      subject(:patch_update) { patch spree.api_checkout_path(order.to_param), headers: headers, params: params }

      let(:headers) { { 'X-Spree-Order-Token' => order.guest_token } }

      let(:order) { create :order_ready_for_payment, bill_address: bill_address }
      let(:bill_address) { build :address, state: md }
      let(:params) { { order: { bill_address_attributes: { state_id: nil, state_name: al.abbr } } } }

      let(:md) { create :state, name: 'Maryland', abbr: 'MD' }
      let!(:al) { create :state, name: 'Alabama', abbr: 'AL' }

      before { Spree::Country.update_all(states_required: true) }

      it 'can update the state by passing state_id: nil' do
        expect(order.bill_address.state).to eq md
        patch_update
        expect(order.reload.bill_address.state).to eq al
      end
    end

    context 'when a solidus_paypal_braintree payment is submitted', :vcr do
      subject(:patch_update) { patch spree.api_checkout_path(order.to_param), params: params }

      let(:guest_order_token) { { 'X-Spree-Order-Token' => order.guest_token } }
      let(:order) { create(:order_ready_for_payment) }
      let(:payment_method) { create(:solidus_paypal_braintree_gateway) }

      shared_examples 'a request with a not yet existing payment' do
        it "sets source's reusable attribute to the value present within params" do
          patch_update
          expect(order.reload.payments.first.source.reusable).to eq(
            params[:order][:payments_attributes][0][:source_attributes][:reusable]
          )
        end
      end

      shared_examples 'a successful request' do
        it 'responds with :ok HTTP status' do
          patch_update
          expect(response).to have_http_status(:ok)
        end

        it 'adds the payment to the order' do
          expect { patch_update }.to change { order.payments.count }.from(0).to(1)
        end
      end

      context 'with a not yet existing valid credit card payment' do
        let(:params) do
          {
            order_token: order.guest_token,
            order: {
              payments_attributes: [
                {
                  payment_method_id: payment_method.id,
                  source_attributes: {
                    nonce: Braintree::Test::Nonce::TransactableVisa,
                    payment_type: SolidusPaypalBraintree::Source::CREDIT_CARD,
                    reusable: false
                  }
                }
              ]
            }
          }
        end

        it_behaves_like 'a successful request'
        it_behaves_like 'a request with a not yet existing payment'
      end

      context 'with a not yet existing valid PayPal payment' do
        let(:params) do
          {
            order_token: order.guest_token,
            order: {
              payments_attributes: [
                {
                  payment_method_id: payment_method.id,
                  source_attributes: {
                    nonce: Braintree::Test::Nonce::PayPalBillingAgreement,
                    payment_type: SolidusPaypalBraintree::Source::PAYPAL,
                    reusable: false
                  }
                }
              ]
            }
          }
        end

        it_behaves_like 'a successful request'
        it_behaves_like 'a request with a not yet existing payment'
      end

      context 'with a not yet existing valid ApplePay payment' do
        let(:params) do
          {
            order_token: order.guest_token,
            order: {
              payments_attributes: [
                {
                  payment_method_id: payment_method.id,
                  source_attributes: {
                    nonce: Braintree::Test::Nonce::ApplePayVisa,
                    payment_type: SolidusPaypalBraintree::Source::APPLE_PAY,
                    reusable: false
                  }
                }
              ]
            }
          }
        end

        it_behaves_like 'a successful request'
        it_behaves_like 'a request with a not yet existing payment'
      end

      context 'with an existing valid credit card payment' do
        let(:solidus_paypal_braintree_source) do
          create :solidus_paypal_braintree_source,
                 :transactable_visa,
                 payment_method: payment_method,
                 user: order.user
        end
        let(:wallet_payment_source) { order.user.wallet.add solidus_paypal_braintree_source }
        let(:params) do
          {
            order_token: order.guest_token,
            order: {
              payments_attributes: [
                {
                  payment_method_id: payment_method.id
                },
                source_attributes: {
                  wallet_payment_source_id: wallet_payment_source.id
                }
              ]
            }
          }
        end

        it_behaves_like 'a successful request'
      end

      context 'with an existing valid PayPal payment' do
        let(:solidus_paypal_braintree_source) do
          create :solidus_paypal_braintree_source,
                 :paypal_billing_agreement,
                 payment_method: payment_method,
                 user: order.user
        end
        let(:wallet_payment_source) { order.user.wallet.add solidus_paypal_braintree_source }
        let(:params) do
          {
            order_token: order.guest_token,
            order: {
              payments_attributes: [
                {
                  payment_method_id: payment_method.id
                },
                source_attributes: {
                  wallet_payment_source_id: wallet_payment_source.id
                }
              ]
            }
          }
        end

        it_behaves_like 'a successful request'
      end

      context 'with an existing valid ApplePay payment' do
        let(:solidus_paypal_braintree_source) do
          create :solidus_paypal_braintree_source,
                 :apple_pay_visa,
                 payment_method: payment_method,
                 user: order.user
        end
        let(:wallet_payment_source) { order.user.wallet.add solidus_paypal_braintree_source }
        let(:params) do
          {
            order_token: order.guest_token,
            order: {
              payments_attributes: [
                {
                  payment_method_id: payment_method.id
                },
                source_attributes: {
                  wallet_payment_source_id: wallet_payment_source.id
                }
              ]
            }
          }
        end

        it_behaves_like 'a successful request'
      end
    end

    context 'when not advancing an order' do
      let(:do_request) { patch spree.api_checkout_path(order.to_param), params: params }
      let(:order) { create(:order_ready_for_payment) }
      let(:new_email) { 'nolan.camp@maisonette.com' }
      let(:params) do
        {
          order_token: order.guest_token,
          order: {
            email: new_email
          },
          hold_state: true
        }
      end

      it 'responds with :ok' do
        expect { do_request }.not_to change(order, :state)
        expect(order.reload.email).to eq new_email
      end

      context 'when updating shipping methods' do
        let(:fast_method) { create :shipping_method, name: 'Fast' }
        let(:shipment) { order.shipments.first }
        let(:new_rate) { shipment.shipping_rates.create!(shipping_method: fast_method, cost: 200) }
        let(:params) { super().merge(new_params) }
        let(:new_params) do
          {
            order: {
              shipments_attributes: {
                '0': { selected_shipping_rate_id: new_rate.id, id: shipment.id }
              }
            }
          }
        end

        it 'can update the shipping_method' do
          do_request
          expect(shipment.reload.shipping_method).to eq fast_method
        end
      end
    end
  end

  describe 'PUT complete' do
    subject(:put_complete) { put "/api/checkouts/#{order.number}/complete", params: { order_token: order.guest_token } }

    let(:order) { create(:order_ready_to_complete) }
    let(:taxon_clothing) { create :taxon, :clothing }
    let(:taxon_clothing_girl) { create :taxon, :clothing_girl, parent: taxon_clothing }

    it 'returns breadcrumb_taxons for each line item' do
      order.products.last.taxons << taxon_clothing_girl

      put_complete

      breadcrumb_taxons_array = json_response[:line_items].last[:breadcrumb_taxons]

      expect(breadcrumb_taxons_array.count).to eq 2
    end

    context 'when the order contains solidus_paypal_braintree payments', :vcr do
      subject(:put_complete) { put "/api/checkouts/#{order.number}/complete", params: params }

      let(:guest_order_token) { { 'X-Spree-Order-Token' => order.guest_token } }
      let(:order) { create(:order_ready_to_complete, payment_type: :solidus_paypal_braintree_credit_card_payment) }
      let(:payment) { order.payments.first }
      let(:payment_method) { payment.payment_method }
      let(:params) do
        {
          order_token: order.guest_token,
          expected_total: order.total,
        }
      end

      it 'responds with :ok HTTP status' do
        put_complete
        expect(response).to have_http_status(:ok)
      end

      it 'updates order state' do
        expect { put_complete }.to change { order.reload.state }.from('confirm').to('complete')
      end

      it 'updates payment state' do
        expect { put_complete }.to change { payment.reload.state }.from('checkout').to('completed')
      end
    end

    context 'when the order has shipments without shipping_method' do
      subject(:put_complete) { put "/api/checkouts/#{order.number}/complete", headers: headers, params: {} }

      let(:headers) { { 'X-Spree-Order-Token' => order.guest_token } }
      let(:order) { create(:order_ready_to_complete) }
      let(:invalid_shipment) { order.shipments.sample }
      let(:expected_error_message) do
        I18n.t('spree.api.order.no_shipping_method', invalid_shipments: invalid_shipment.number)
      end

      before do
        invalid_shipment.shipping_rates.destroy_all
      end

      it 'avoid order to be completed' do
        put_complete
        expect(status).to eq 422
        expect(json_response[:error]).to include expected_error_message
      end
    end
  end

  describe 'PUT update' do
    context 'when updating the address' do
      let(:order) { create(:order_with_line_items, bill_address: nil, ship_address: nil) }
      let(:ship_address) do
        {
          'first_name' => 'Richard',
          'last_name' => 'Shipping',
          'address1' => '55 Washington St',
          'address2' => '',
          'city' => 'Brooklyn',
          'zipcode' => '11201',
          'phone' => '+1 (123) 123-1231',
          'country_iso' => 'US',
          'state_name' => 'NY'
        }
      end
      let(:bill_address) do
        {
          'first_name' => 'Richard',
          'last_name' => 'Billing',
          'address1' => '12 Castle Street',
          'address2' => '',
          'city' => 'London',
          'zipcode' => 'E13 9GA',
          'phone' => '+1 (123) 123-1231',
          'country_iso' => 'GB',
          'state_name' => ''
        }
      end
      let(:params) do
        {
          email: 'test@email.com',
          ship_address_attributes: ship_address,
          bill_address_attributes: bill_address,
          use_billing: use_billing
        }
      end
      let(:use_billing) { true }

      before do
        create :country, iso: 'US'
        create :country, iso: 'GB'
      end

      context 'when use_billing is true' do
        it 'set billing address equal to shipping' do
          put "/api/checkouts/#{order.number}", params: { order_token: order.guest_token, order: params }

          expect(json_response['bill_address']).to eq(json_response['ship_address'])
        end
      end

      context 'when use_billing is false' do
        let(:use_billing) { false }

        it 'does not change billing_address to shipping_address' do
          put "/api/checkouts/#{order.number}", params: { order_token: order.guest_token, order: params }

          expect(json_response['bill_address']).to match hash_including('lastname' => 'Billing',
                                                                        'city' => 'London')
          expect(json_response['ship_address']).to match hash_including('lastname' => 'Shipping',
                                                                        'city' => 'Brooklyn')
        end
      end
    end

    context 'when updating gift details' do
      let(:order) { create(:order_ready_for_payment) }
      let(:email) { FFaker::Internet.email }
      let(:message) { FFaker::Lorem.sentence(2) }
      let(:params) { { is_gift: true, gift_email: email, gift_message: message } }

      before do
        checkout_params = { order_token: order.guest_token, order: params, hold_state: true }
        put "/api/checkouts/#{order.number}", params: checkout_params
      end

      it 'can mark the order as a gift' do
        expect(json_response[:is_gift]).to eq true
        expect(json_response[:gift_email]).to eq email
        expect(json_response[:gift_message]).to eq message
      end
    end

    context 'when holding state' do
      let(:do_request) { put "/api/checkouts/#{order.number}", headers: headers, params: params }
      let(:params) { { order_token: order.guest_token, order: order_params, hold_state: true } }
      let(:order_params) { { bill_address_attributes: bill_address.attributes } }

      let(:order) { create :order_ready_for_payment }
      let(:bill_address) { build :bill_address }

      before do
        allow(Spree::Order).to receive(:find_by!).with(number: order.number).and_return order
        allow(order).to receive_messages(recalculate: true, next: false)
        allow(order).to receive(:recompute_shipping)
        do_request
      end

      it 'updates and recalculates the order without advancing state' do
        expect(json_response[:bill_address]).to match hash_including(address1: bill_address.address1)
        expect(json_response[:state]).to eq 'payment'
        expect(order).to have_received(:recalculate).at_least(:once)
        expect(order).not_to have_received :next
      end
    end

    context 'when the order is on confirm state' do
      let(:do_request) { put "/api/checkouts/#{order.number}", headers: headers, params: params }
      let(:params) { { order_token: order.guest_token, hold_state: false } }
      let(:order) { create :order_ready_to_complete }

      before do
        allow(Spree::Order).to receive(:find_by!).with(number: order.number).and_return order
        allow(order).to receive_messages(recalculate: true, next: false)
        allow(order).to receive(:recompute_shipping)
        do_request
      end

      it 'does not try to advance state' do
        expect(json_response[:state]).to eq 'confirm'
        expect(order).not_to have_received :recalculate
        expect(order).not_to have_received :next
      end
    end

    context 'when order.next returns false' do
      let(:do_request) { put "/api/checkouts/#{order.number}", headers: headers, params: params }
      let(:params) { { order_token: order.guest_token, hold_state: false } }
      let(:order) { create :order_ready_for_payment }

      before do
        allow(Spree::Order).to receive(:find_by!).with(number: order.number).and_return order
        allow(order).to receive(:next).and_return(false)
        allow(Sentry).to receive(:capture_exception_with_message)

        do_request
      end

      it 'captures the exception with Sentry' do
        expect(Sentry).to have_received(:capture_exception_with_message)
        expect(response.code).to eq '422'
      end
    end
  end
end
