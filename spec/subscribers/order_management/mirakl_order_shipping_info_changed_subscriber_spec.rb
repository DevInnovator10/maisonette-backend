# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::MiraklOrderShippingInfoChangedSubscriber, :subscriber do
  describe '#handle_mirakl_order_shipping_info_changed' do
    subject(:mirakl_order_shipping_info_changed_event) do
      Spree::Event.fire('mirakl_order_shipping_info_changed', mirakl_order: mirakl_order)
    end

    let(:mirakl_order) { create(:mirakl_order, commercial_order: mirakl_commercial_order) }

    let(:solidus_order) { create(:order) }
    let(:mirakl_commercial_order) { create(:mirakl_commercial_order, spree_order: solidus_order) }
    let(:sale_order) { create(:sales_order, spree_order: solidus_order, order_management_ref: '1234') }

    before { sale_order }

    context 'when send order management enabled' do
      before do
        allow(Flipper).to receive(:enabled?).and_return(true)
        allow(::Easypost::CreateTrackerInteractor).to receive(:call)
      end

      it 'calls Mirakl::UpdateShipmentTrackingInteractor' do
        mirakl_order_shipping_info_changed_event

        expect(::Easypost::CreateTrackerInteractor).to have_received(:call).with(
          tracking_code: mirakl_order.shipping_tracking,
          carrier: mirakl_order.shipping_carrier_code,
          mirakl_order: mirakl_order
        )
      end

      context 'when mirakl order state changed' do
        before do
          mirakl_order.update(state: 'SHIPPING')
        end

        it 'does not create a UpsertShipments command' do
          expect { mirakl_order_shipping_info_changed_event }.not_to(
            change(OrderManagement::Commands::UpsertShipments, :count)
          )
        end
      end

      context "when mirakl order state didn't change" do
        it 'creates a UpsertShipments command with include_items: false' do
          command_data = { 'mirakl_order_id' => mirakl_order.id, 'include_items' => false }

          expect { mirakl_order_shipping_info_changed_event }.to(
            change(OrderManagement::Commands::UpsertShipments, :count).by(1)
          )

          command = OrderManagement::Commands::UpsertShipments.last
          expect(command.order_management_ref).to eq '1234'
          expect(command.data).to eq(command_data)
        end
      end

      context 'when there is an error' do
        let(:rails_logger) { instance_double ActiveSupport::Logger, error: true }
        let(:exception) { StandardError.new }

        before do
          allow(::Easypost::CreateTrackerInteractor).to receive(:call).and_raise(exception)
          allow(Rails.logger).to receive(:error).with(exception)
          allow(Sentry).to receive(:capture_exception_with_message).with(exception)
        end

        it 'logs and capture the exception' do
          mirakl_order_shipping_info_changed_event

          expect(Rails.logger).to have_received(:error).with(exception)
          expect(Sentry).to have_received(:capture_exception_with_message).with(exception)
        end
      end
    end

    context 'when send order management not enabled' do
      before do
        allow(::Mirakl::UpdateShipmentTrackingInteractor).to receive(:call)
      end

      it 'calls Mirakl::UpdateShipmentTrackingInteractor' do
        mirakl_order_shipping_info_changed_event

        expect(::Mirakl::UpdateShipmentTrackingInteractor).to have_received(:call).with(mirakl_order: mirakl_order)
      end

      context 'when there is an error' do
        let(:rails_logger) { instance_double ActiveSupport::Logger, error: true }
        let(:exception) { StandardError.new }

        before do
          allow(::Mirakl::UpdateShipmentTrackingInteractor).to receive(:call).and_raise(exception)
          allow(Rails.logger).to receive(:error).with(exception)
          allow(Sentry).to receive(:capture_exception_with_message).with(exception)
        end

        it 'logs and capture the exception' do
          mirakl_order_shipping_info_changed_event

          expect(Rails.logger).to have_received(:error).with(exception)
          expect(Sentry).to have_received(:capture_exception_with_message).with(exception)
        end
      end
    end
  end
end
