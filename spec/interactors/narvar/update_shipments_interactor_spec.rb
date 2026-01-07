# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Narvar::UpdateShipmentsInteractor, narvar: true do
  include_context 'with Narvar context'

  describe '#call' do
    subject(:described_method) { described_class.call(order: order) }

    let(:order) { nil }

    before do
      allow(Spree::Order).to receive(:find_by!).and_return(order)
    end

    it { expect(described_class.new).to be_a Interactor }
    it { expect(described_method).to be_failure }
    it { expect(described_method.error).to eq 'Order required' }

    context 'without a Narvar order created' do
      let(:order) { build(:completed_order_with_totals) }

      it { expect(described_method).to be_failure }
      it { expect(described_method.error).to eq 'Narvar Order required' }
    end

    context 'with a completed order' do
      let(:order) { build(:shipped_order, line_items_count: 3).tap { |order| order.completed_at = Time.current } }

      context 'with a new Narvar order' do
        before { order.narvar_order = build(:narvar_order) }

        it { expect(described_method).to be_failure }
        it { expect(described_method.error).to eq 'Invalid Narvar Order state' }
      end

      context 'with invalid data' do
        before do
          order.update_column(:number, 'R00080001')
          ::Narvar::SyncOrderWorker.new.perform(order.number)
          order.shipments.first.update_columns(state: 'shipped', shipped_at: Time.current, tracking: '')
        end

        it 'fails to update an order on Narvar API', :vcr do
          expect(described_method).to be_failure
          expect(described_method.narvar_order).to be_failed_submission
          expect(described_method.narvar_order.result_code).not_to eq 200
          expect(described_method.narvar_order.error_messages).to include 'invalid.order.shipments.tracking'
        end
      end

      context 'with a Narvar order created' do
        before do
          order.update_column(:number, 'R00080002')
          ::Narvar::SyncOrderWorker.new.perform(order.number)
          order.shipments.first.update_columns(state: 'shipped', shipped_at: Time.current)
        end

        it 'updates an order on Narvar API', :vcr do
          expect(described_method).to be_success
          expect(described_method.narvar_order).to be_submitted
          expect(described_method.narvar_order.result_code).to eq 200
          expect(described_method.narvar_order.error_messages).to be_nil
        end
      end

      context 'with a Narvar order failed to submit' do
        before do
          order.update_column(:number, 'R00080003')
          ::Narvar::SyncOrderWorker.new.perform(order.number)
          order.shipments.first.update_columns(state: 'shipped', shipped_at: Time.current, tracking: '')
        end

        it 'updates an order on Narvar API', :vcr do
          expect(described_class.call(order: order)).to be_failure
          order.shipments.first.update_column(:tracking, '1234567890')
          expect(described_method).to be_success
          expect(described_method.narvar_order).to be_submitted
          expect(described_method.narvar_order.result_code).to eq 200
          expect(described_method.narvar_order.error_messages).to be_nil
        end
      end
    end
  end
end
