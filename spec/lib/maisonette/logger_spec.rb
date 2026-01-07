# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Logger do
  it { expect(described_class).to be < ActiveSupport::Logger }

  describe '<<' do
    let(:logger) { described_class.new(STDOUT) }

    before do
      allow(logger).to receive(:info)
    end

    it 'calls info with the message' do
      logger << 'message '
      expect(logger).to have_received(:info).with 'message'
    end
  end
end
