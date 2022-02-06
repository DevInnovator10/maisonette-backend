# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Narvar::SyncOrderWorker, narvar: true do
  include_context 'with Narvar context'

  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform(order_number) }

    let(:order_number) {}

    context 'without arguments' do
      it { expect { worker.perform }.to raise_error ArgumentError }
    end

    context 'with an invalid record' do
      let(:order_number) { '1' }

      before do
        allow(Sentry).to receive(:capture_exception_with_message)

        perform
      end

      it 'captures an exception in Sentry' do
        expect(Sentry).to have_received(:capture_exception_with_message).with(instance_of(NoMethodError), message: '1')
      end
    end

    context 'with valid arguments' do
      let(:order_number) { order.number }
      let(:order) { nil }

      before do
        allow(Spree::Order).to receive(:find_by).and_return(order)
      end

      context 'when the order is not yet shipped' do
        before do
          allow(Narvar::CreateOrderInteractor).to receive(:call!)
          allow(Narvar::UpdateOrderInteractor).to receive(:call!).with(order: order)

          perform
        end

        context 'when there is narvar order' do
          let(:order) { build_stubbed(:order_ready_to_ship) }

          it 'calls CreateOrderInteractor' do
            expect(Narvar::CreateOrderInteractor).to have_received(:call!).with(order: order)
          end
        end

        context 'with a narvar updated order' do
          let(:order) { create(:order_ready_to_ship, :narvar_updated) }

          it 'calls UpdateOrderInteractor' do
            expect(Narvar::UpdateOrderInteractor).to have_received(:call!).with(order: order)
          end

          context 'when the narvar order is :failed_creation' do
            let(:order) { create(:order_ready_to_ship, :narvar_failed_creation) }

            it 'calls CreateOrderInteractor' do
              expect(Narvar::CreateOrderInteractor).to have_received(:call!).with(order: order)
            end
          end
        end

        context 'with a canceled order' do
          let(:order) { build_stubbed(:order_ready_to_ship, :narvar_updated, state: :canceled) }

          it 'calls UpdateOrderInteractor' do
            expect(Narvar::UpdateOrderInteractor).to have_received(:call!).with(order: order)
          end
        end
      end

      context 'when the order is shipped' do
        before do
          allow(order).to receive(:shipped?).and_return(true)
          allow(Narvar::CreateOrderWithShipmentsOrganizer).to receive(:call!)
          allow(Narvar::UpdateOrderWithShipmentsOrganizer).to receive(:call!).with(order: order)

          perform
        end

        context 'when there is no narvar order' do
          let(:order) { build_stubbed(:completed_order_with_totals) }

          it 'calls CreateOrderWithShipmentsOrganizer' do
            expect(Narvar::CreateOrderWithShipmentsOrganizer).to have_received(:call!).with(order: order)
          end
        end

        context 'with a narvar updated shipped order' do
          let(:order) do
            build_stubbed(:completed_order_with_totals, narvar_order: build(:narvar_order, state: :created))
          end

          it 'calls UpdateOrderWithShipmentsOrganizer' do
            expect(Narvar::UpdateOrderWithShipmentsOrganizer).to have_received(:call!).with(order: order)
          end

          context 'when the narvar order is :failed_creation' do
            let(:order) { create(:order_ready_to_ship, :narvar_failed_creation) }

            it 'calls CreateOrderInteractor' do
              expect(Narvar::CreateOrderWithShipmentsOrganizer).to have_received(:call!).with(order: order)
            end
          end
        end
      end
    end
  end
end
