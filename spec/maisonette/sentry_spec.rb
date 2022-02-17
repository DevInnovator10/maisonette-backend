# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Sentry do
  describe '.error_message' do
    subject(:error_message) { described_class.error_message(event, hint) }

    let(:event) { instance_double Sentry::Event, message: event_message, extra: extra }
    let(:event_message) { 'some event message' }
    let(:extra) { { event_hash: 'event_hash_details' } }
    let(:hint) { { exception: exception } }
    let(:exception) { StandardError.new('standard error message') }

    before do
      allow(event).to receive(:is_a?).with(Sentry::Event).and_return(true)
    end

    it 'returns a hash error message' do
      expect(error_message).to eq(event: { message: event_message, extra: extra },
                                  exception: exception.inspect,
                                  message: "#{exception.message} - #{event_message}",
                                  backtrace: nil)
    end
  end
end
