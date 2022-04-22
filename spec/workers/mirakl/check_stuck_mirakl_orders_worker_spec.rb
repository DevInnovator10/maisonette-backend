# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::CheckStuckMiraklOrdersWorker, mirakl: true do
  describe '#perform' do
    let(:mirakl_order_stuck) { create :mirakl_order, state: :WAITING_DEBIT_PAYMENT }
    let(:mirakl_order_not_stuck1) { create :mirakl_order, state: :WAITING_DEBIT_PAYMENT }
    let(:mirakl_order_not_stuck2) { create :mirakl_order, state: :SHIPPING }

    let(:error_message) do
      "Order stuck in state: #{mirakl_order_stuck.state} - #{mirakl_order_stuck.logistic_order_id}"
    end

    context 'when there are mirakl orders stuck' do
      before do
        mirakl_order_stuck.update_columns(updated_at: 2.hours.ago)
        mirakl_order_not_stuck1
        mirakl_order_not_stuck2

        allow(Sentry).to receive(:capture_message)

        described_class.new.perform
      end

      it 'captures the stuck mirakl orders via Sentry' do
        expect(Sentry).to have_received(:capture_message).with(error_message, tags: { notify: :order_sync_issues })
      end
    end

    context 'when there are no mirakl orders stuck' do
      before do
        allow(Sentry).to receive(:capture_message)

        described_class.new.perform
      end

      it 'does not capture an error message' do
        expect(Sentry).not_to have_received(:capture_message)
      end
    end
  end
end
