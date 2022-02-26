# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::CategorySynchronizationWorker, mirakl: true do
  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    let(:interactor_context) do
      double Interactor::Context, success?: sync_success # rubocop:disable RSpec/VerifiedDoubles
    end

    before do
      allow(Mirakl::CategorySynchronizationInteractor).to receive(:call).and_return(interactor_context)
      allow(Sentry).to receive(:capture_message)
      perform
    end

    context 'when category synchronization is successful' do
      let(:sync_success) { true }

      it 'does not send any messages to Sentry' do
        expect(Mirakl::CategorySynchronizationInteractor).to have_received(:call)
        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    context 'when category syncrhonization is a failure' do
      let(:sync_success) { false }

      it 'sends a notification to sentry' do
        expect(Mirakl::CategorySynchronizationInteractor).to have_received(:call)
        expect(Sentry).to have_received(:capture_message)
      end
    end
  end
end
