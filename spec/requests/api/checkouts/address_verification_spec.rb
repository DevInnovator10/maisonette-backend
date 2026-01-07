# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/checkouts', type: :request do
  let(:headers) { { 'X-Spree-Order-Token' => order.guest_token } }

  describe '#update' do
    subject(:update) { put spree.api_checkout_path(order.to_param), headers: headers, params: params }

    let(:order) { create :order_ready_to_complete, line_items_count: 1 }

    context 'when address_verification is true' do
      let(:params) do
        { id: order.number,
          hold_state: true,
          address_verification: true,
          format: :json }
      end

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

      let(:easypost_address_id) {}

      before do
        order.shipping_address.update_columns(easypost_address_id: easypost_address_id)
        allow(Spree::Order).to receive(:find_by).with(number: order.number).and_return(order)
        allow(order.shipping_address).to receive(:to_easypost_address!).and_return(easypost_address)
        allow(order).to receive(:recompute_shipping)
      end

      context 'when it is successful' do
        before { update }

        it 'calls easypost to validate the address' do
          expect(order.shipping_address).to have_received(:to_easypost_address!).with(verify: true)
        end

        it 'updates the residential attribute of the shipping address' do
          expect(order.shipping_address.residential).to eq(true)
        end

        it 'returns the address_verification object in the order response' do
          expect(json_response[:address_verification]).to(
            eq('address' => { 'street1' => 'WASHINGTON ST',
                              'street2' => '',
                              'city' => 'BROOKLYN',
                              'state' => 'WA',
                              'zip' => '11201-1036',
                              'country' => 'US' },
               'success' => true,
               'suggestions' => [
                 { 'field' => 'street1', 'message' => 'House number missing', 'suggestion' => nil },
                 { 'field' => 'state', 'message' => 'State does not match zipcode', 'suggestion' => 'NY' }
               ])
          )
        end

        context 'when verifications is "delivery" instead of "zip4"' do
          let(:easypost_verifications) { double EasyPost::EasyPostObject, delivery: easypost_delivery }
          let(:easypost_delivery) do
            double EasyPost::EasyPostObject,
                   success: true,
                   errors: [
                     easypost_error1,
                     easypost_error2
                   ]
          end
          # rubocop:enable RSpec/VerifiedDoubles

          it 'returns the address_verification object in the order response' do
            expect(json_response[:address_verification]).to(
              eq('address' => { 'street1' => 'WASHINGTON ST',
                                'street2' => '',
                                'city' => 'BROOKLYN',
                                'state' => 'WA',
                                'zip' => '11201-1036',
                                'country' => 'US' },
                 'success' => true,
                 'suggestions' => [
                   { 'field' => 'street1', 'message' => 'House number missing', 'suggestion' => nil },
                   { 'field' => 'state', 'message' => 'State does not match zipcode', 'suggestion' => 'NY' }
                 ])
            )
          end
        end

        context 'when the shipping_address is already validated' do
          let(:easypost_address_id) { 'adr_123' }

          it 'does not call easypost to validate the address' do
            expect(order.shipping_address).not_to have_received(:to_easypost_address!)
          end

          it 'does not return the address_verification object in the order response' do
            expect(json_response[:address_verification]).to eq nil
          end
        end
      end

      context 'when an error is thrown' do
        let(:standard_error) { StandardError.new('issue validating address') }
        let(:error_message) { "Failed to verify easypost address for #{order.number}" }

        before do
          allow(order.shipping_address).to receive(:to_easypost_address!).and_raise(standard_error)
          allow(Sentry).to receive(:capture_exception_with_message)

          update
        end

        it 'returns the order response' do
          expect(json_response[:number]).to eq order.number
          expect(json_response[:address_verification]).to eq nil
        end

        it 'captures the error with Sentry' do
          expect(Sentry).to have_received(:capture_exception_with_message).with(standard_error, message: error_message)
        end
      end
    end
  end
end
