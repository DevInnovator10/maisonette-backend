# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::MarkDownDeactivateWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:query) { instance_double ActiveRecord::Relation }
    let(:mark_down) { instance_double Spree::MarkDown, title: 'A Sample Mark Down', id: 1, update!: true }
    let(:mailer) { instance_double ActionMailer::MessageDelivery, deliver_now: true }

    before do
      allow(Spree::MarkDown).to receive_messages(to_deactivate: query)
      allow(query).to receive(:find_each).and_yield(mark_down)
    end

    context 'when everything goes well' do
      before do
        allow(Spree::MarkDownDeactivateMailer).to receive(:notify_deactivate).and_return(mailer)

        worker.perform
      end

      it 'deactivate mark_down' do
        expect(mark_down).to have_received(:update!).with(active: false)
      end

      it 'sends deactivation notification' do
        expect(Spree::MarkDownDeactivateMailer).to have_received(:notify_deactivate).with(mark_down)

        expect(mailer).to have_received(:deliver_now)
      end
    end

    context 'when an exceptions accurs while deactivating the mark down' do
      before do
        allow(Sentry).to receive(:capture_exception_with_message)
        allow(mark_down).to receive(:update!).and_raise(RuntimeError)

        worker.perform
      end

      it 'sends the exception to Sentry' do
        expect(Sentry).to have_received(:capture_exception_with_message)
      end
    end
  end
end
