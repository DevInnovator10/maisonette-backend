# frozen_string_literal: true

require 'sidekiq/testing'
require 'rails_helper'

RSpec.describe Klaviyo::CompletedOrderWorker, type: :worker do
    let(:gid) { FFaker::Lorem.characters(10) }
  let(:line_item_gids) { Array.new(5) { FFaker::Lorem.characters(10) } }
  let(:event) { :complete }

  let(:worker_args) { [gid, line_item_gids] }
  let(:worker_payloads) { line_item_gids.map { |gid| [gid, 'ordered_product'] } }
  let(:order_args) { { gid: gid, event: 'complete' } }

  let(:context) { instance_double Interactor::Context, failure?: false }

  before do
    allow(Klaviyo::TrackerInteractor).to receive(:call).and_return context
    allow(Klaviyo::TrackerWorker).to receive(:perform_async).and_call_original
    allow(Sentry).to receive(:capture_message)
  end

  describe '#perform' do
    it 'calls the tracker interactor with the order gid and event' do
      described_class.new.perform(*worker_args)
      expect(Klaviyo::TrackerInteractor).to have_received(:call).with(order_args)
    end

    it 'creates workers for each line item' do
      expect { described_class.new.perform(*worker_args) }.to change(Klaviyo::TrackerWorker.jobs, :size).by(5)
      worker_payloads.each do |payload|
        expect(Klaviyo::TrackerWorker).to have_received(:perform_async).once.with(*payload)
      end
    end

    it 'does not capture an error message' do
      described_class.new.perform(*worker_args)
      expect(Sentry).not_to have_received(:capture_message)
    end

    context 'when unsuccessful' do
      let(:context) do
        double Interactor::Context, failure?: true, message: message # rubocop:disable RSpec/VerifiedDoubles
      end
      let(:message) { FFaker::Lorem.sentence }

      it 'captures an error message' do
        described_class.new.perform(*worker_args)
        expect(Sentry).to have_received(:capture_message).with(context.message)
      end
    end
  end
end
