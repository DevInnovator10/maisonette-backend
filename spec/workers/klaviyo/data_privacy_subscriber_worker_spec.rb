# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Klaviyo::DataPrivacySubscriberWorker do
  let(:klass) { class_double('Klaviyo::DataPrivacySubscriberInteractor').as_stubbed_const }
  let(:context) { instance_double Interactor::Context, failure?: false }

  let(:subscriber) { create :subscriber }
  let(:id) { subscriber.id }

  before do
    allow(Maisonette::Subscriber).to receive(:find_by).with(id: id).and_return subscriber
    allow(klass).to receive(:call).and_return context
    allow(Sentry).to receive(:capture_message)
    described_class.new.perform(id)
  end

  describe '#perform' do
    it 'calls the data privacy subscriber interactor with the provided subscriber' do
      expect(klass).to have_received(:call).with(subscriber: subscriber)
    end

    it 'does not capture an error message' do
      expect(Sentry).not_to have_received(:capture_message)
    end

    context 'when unsuccessful' do
      let(:context) do
        # rubocop:disable RSpec/VerifiedDoubles
        double Interactor::Context, failure?: true, message: message, invalid_email_address: false
        # rubocop:enable RSpec/VerifiedDoubles
      end
      let(:message) { FFaker::Lorem.sentence }

      it 'captures an error message' do
        expect(Sentry).to have_received(:capture_message).with(message)
      end
    end
  end
end
