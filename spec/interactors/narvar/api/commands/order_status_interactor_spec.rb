# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Narvar::Api::Commands::OrderStatusInteractor, narvar: true do
  describe '#call' do
    subject(:described_method) { described_class.call(params) }

    let(:params) {}

    it { is_expected.to be_failure }
    it { expect(described_method.error).to eq 'Order number required' }

    context 'with an order number' do
      before do
        response = instance_double(RestClient::Response, body: '{}')
        allow(RestClient::Request).to receive(:execute).and_return(response)
        described_method
      end

      let(:order) { build_stubbed :order, number: 'R12345678' }
      let(:params) { { order_number: order.number } }

      it { expect(described_method).to be_success }
      it { expect(RestClient::Request).to have_received(:execute).with(hash_including(method: :get)) }
    end
  end
end
