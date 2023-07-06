# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sentry::Hub::CaptureExceptionWithMessage do
  let(:described_class) { Sentry::Hub }

  describe '#capture_exception_with_message' do
    subject(:capture_exception_with_message) do
      hub.capture_exception_with_message(exception, options) { some_block }
    end

    let(:hub) { described_class.new(client, scope) }
    let(:client) { instance_double Sentry::Client, event_from_exception_with_message: event }
    let(:scope) { instance_double Sentry::Scope }

    let(:exception) { StandardError.new }
    let(:options) { { message: 'error message', extra: { order_id: 1 } } }
    let(:some_block) { -> { 'some block' } }

    let(:event) { instance_double Sentry::Event }

    before do
      allow(hub).to receive(:capture_event).and_return(event)

      capture_exception_with_message
    end

    it 'calls event_from_exception_with_message on the client' do
      expect(client).to have_received(:event_from_exception_with_message).with(exception,
                                                                               options[:message],
                                                                               exception: exception)
    end

    it 'calls capture_event' do
      expect(hub).to have_received(:capture_event).with(event,
                                                        { extra: options[:extra],
                                                          hint: { exception: exception } },
                                                        &some_block)
    end

    it 'returns the event' do
      expect(capture_exception_with_message).to eq event
    end
  end
end
