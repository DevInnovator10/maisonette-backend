# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::SaveEasypostAddressSubscriber, :subscriber do
  let(:order) { create(:order_ready_to_ship) }

  describe '#save_easypost_address!' do
    subject(:order_finalized_event) { Spree::Event.fire 'order_finalized', order: order }

    let(:existing_easypost_address_id) {}
    let(:easypost_address) { instance_double EasyPost::Address, id: 'adr_123' }

    before do
      allow(order.ship_address).to receive_messages(easypost_address_id: existing_easypost_address_id,
                                                    to_easypost_address!: easypost_address,
                                                    update_columns: nil)
      allow(order).to receive(:persist_user_address!)
    end

    context 'when the feature flag is enabled' do
      before { Flipper[:checkout_address_verification].enable }

      context 'when it is successful' do
        before { order_finalized_event }

        context 'when there is no saved easypost_address_id' do
          let(:existing_easypost_address_id) {}

          it 'calls to_easypost_address! with verify:false' do
            expect(order.ship_address).to have_received(:to_easypost_address!).with(verify: false)
          end

          it 'updates the ship_address with easypost_address_id' do
            expect(order.ship_address).to have_received(:update_columns).with(easypost_address_id: easypost_address.id)
          end

          it 'updates the address book' do
            expect(order).to have_received(:persist_user_address!)
          end
        end

        context 'when there is an existing easypost_address_id' do
          let(:existing_easypost_address_id) { 'adr_456' }

          it 'does not update the ship_address with easypost_address_id ' do
            expect(order.ship_address).not_to have_received(:update_columns)
          end

          it 'does not update the address book' do
            expect(order).not_to have_received(:persist_user_address!)
          end
        end
      end

      context 'when it is unsuccessful' do
        let(:standard_error) { StandardError.new('foo') }
        let(:error_message) { "Unable to save easypost_address_id to order: #{order.number}" }

        before do
          allow(order.ship_address).to receive(:easypost_address_id).and_raise(standard_error)
          allow(Sentry).to receive(:capture_exception_with_message)

          order_finalized_event
        end

        it 'captures the exception with Sentry' do
          expect(Sentry).to have_received(:capture_exception_with_message).with(standard_error, message: error_message)
        end
      end
    end

    context 'when the feature flag is enabled' do
      before do
        Flipper[:checkout_address_verification].disable

        order_finalized_event
      end

      it 'does nothing' do
        expect(order.ship_address).not_to have_received(:easypost_address_id)
      end
    end
  end
end
