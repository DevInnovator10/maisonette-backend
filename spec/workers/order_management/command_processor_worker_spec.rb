# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::CommandProcessorWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(command.order_management_ref) }

    let(:command) do
      instance_double(OrderManagement::OmsCommand, fail_count: fail_count, order_management_ref: '123')
    end
    let(:fail_count) { nil }

    before do
      allow(OrderManagement::OmsCommand).to receive(:next_runnable_for).with(
        command.order_management_ref
      ).and_return(command)
      allow(command).to receive(:execute!)
      allow(described_class).to receive(:perform_async).with(
        command.order_management_ref
      )
    end

    it 'calls CommandProcessorWorker' do
      perform

      expect(command).to have_received(:execute!)
      expect(described_class).to have_received(:perform_async)
    end

    context 'when fail count exceed PROCESS_ATTEMPTS value' do
      let(:fail_count) { OrderManagement::OmsCommand::PROCESS_ATTEMPTS }

      it 'does not re-enqueue the worker' do
        perform

        expect(described_class).not_to have_received(:perform_async)
      end
    end

    context 'when there are not other commands' do
      before do
        allow(OrderManagement::OmsCommand).to receive(:next_runnable_for).with(
          command.order_management_ref
        ).and_return(command, nil)
      end

      it 'does not re-enqueue the worker' do
        perform

        expect(described_class).not_to have_received(:perform_async)
      end
    end
  end
end
