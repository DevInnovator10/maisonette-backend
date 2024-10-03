# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Klaviyo::TrackerWorker do
    let(:gid) { FFaker::Lorem.characters }
  let(:event) { 'complete' }

  let(:args) { [gid, event] }

  let(:context) { instance_double Interactor::Context, failure?: false }

  before do
    allow(Klaviyo::TrackerInteractor).to receive(:call).and_return context
    allow(Sentry).to receive(:capture_message)
    described_class.new.perform(*args)
  end

  describe '#perform' do
    it 'calls the tracker interactor with the correct arguments' do
      expect(Klaviyo::TrackerInteractor).to have_received(:call).with(gid: gid, event: event)
    end

    it 'does not capture an error message' do
      expect(Sentry).not_to have_received(:capture_message)
    end

    context 'when unsuccessful' do
      let(:context) do
        double Interactor::Context, failure?: true, message: message # rubocop:disable RSpec/VerifiedDoubles
      end
      let(:message) { FFaker::Lorem.sentence }

      it 'captures an error message' do
        expect(Sentry).to have_received(:capture_message).with(message)
      end
    end
  end
end
