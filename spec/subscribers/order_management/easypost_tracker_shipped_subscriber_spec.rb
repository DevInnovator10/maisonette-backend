# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::EasypostTrackerShippedSubscriber, :subscriber do
  describe '#handle_easypost_tracker_shipped' do
    subject(:easypost_tracker_shipped_event) do
      Spree::Event.fire('easypost_tracker_shipped', easypost_tracker: easypost_tracker)
    end

    let(:easypost_tracker) { create(:easypost_tracker, tracking_code: 'TRACKING') }
    let(:mirakl_order) { create(:mirakl_order, shipment: shipment, commercial_order: mirakl_commercial_order) }
    let(:shipment) { create(:shipment) }

    let(:solidus_order) { create(:order) }
    let(:mirakl_commercial_order) { create(:mirakl_commercial_order, spree_order: solidus_order) }
    let(:sale_order) { create(:sales_order, spree_order: solidus_order, order_management_ref: '1234') }

    before { sale_order }

    context 'when a mirakl order with the same tracking code exists' do
      before do
        allow(Mirakl::Order).to(
          receive(:find_by).with(shipping_tracking: easypost_tracker.tracking_code).and_return(mirakl_order)
        )
      end

      context 'when send order management enabled' do
        before do
          allow(Flipper).to receive(:enabled?).and_return(true)
        end

        it 'creates a UpsertShipment command with status: Shipped' do
          command_data = { 'mirakl_order_id' => mirakl_order.id, 'status' => 'Shipped' }

          expect { easypost_tracker_shipped_event }.to(
            change(OrderManagement::Commands::UpsertShipment, :count).by(1)
          )

          command = OrderManagement::Commands::UpsertShipment.last
          expect(command.order_management_ref).to eq '1234'
          expect(command.data).to eq(command_data)
        end

        context 'when there is an error' do
          let(:rails_logger) { instance_double ActiveSupport::Logger, error: true }
          let(:exception) { StandardError.new }

          before do
            allow(OrderManagement::Commands::UpsertShipment).to receive(:create!).and_raise(exception)
            allow(Rails.logger).to receive(:error).with(exception)
            allow(Sentry).to receive(:capture_exception_with_message).with(exception)
          end

          it 'logs and capture the exception' do
            easypost_tracker_shipped_event

            expect(Rails.logger).to have_received(:error).with(exception)
            expect(Sentry).to have_received(:capture_exception_with_message).with(exception)
          end
        end
      end

      context 'when send order management not enabled' do
        before { allow(shipment).to receive(:ship!) }

        context 'when there is no shipment' do
          before { mirakl_order.shipment = nil }

          it 'does not call shipment.ship!' do
            easypost_tracker_shipped_event

            expect(shipment).not_to have_received(:ship!)
          end
        end

        context 'when there is a shipment' do
          let(:shipped?) { false }

          before { allow(shipment).to receive(:shipped?).and_return(shipped?) }

          context 'when the shipment is not shipped' do
            it 'calls shipment.ship!' do
              easypost_tracker_shipped_event

              expect(shipment).to have_received(:ship!)
            end
          end

          context 'when the shipment is shipped' do
            let(:shipped?) { true }

            it 'does not call shipment.ship!' do
              easypost_tracker_shipped_event

              expect(shipment).not_to have_received(:ship!)
            end
          end
        end
      end

      context 'when there is an error' do
        let(:rails_logger) { instance_double ActiveSupport::Logger, error: true }
        let(:exception) { StandardError.new }

        before do
          allow(Mirakl::Order).to receive(:find_by).and_raise(exception)
          allow(Rails.logger).to receive(:error).with(exception)
          allow(Sentry).to receive(:capture_exception_with_message).with(exception)
        end

        it 'logs and capture the exception' do
          easypost_tracker_shipped_event

          expect(Rails.logger).to have_received(:error).with(exception)
          expect(Sentry).to have_received(:capture_exception_with_message).with(exception)
        end
      end
    end
  end
end
