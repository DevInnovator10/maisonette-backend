# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Narvar::Api::Commands::CreateOrderInteractor, narvar: true do
  describe '#call' do
    subject(:described_method) { described_class.call(params) }

    let(:params) {}

    it { is_expected.to be_failure }
    it { expect(described_method.error).to eq 'Order required' }

    context 'with an order' do
      let(:response) { instance_double(RestClient::Response, body: '{}') }
      let(:order) { build_stubbed :order }

      let(:params) { { order: order } }

      before do
        allow(RestClient::Request).to receive(:execute).and_return(response)
      end

      context 'when it is successful' do
        before { described_method }

        it { expect(described_method).to be_success }
        it { expect(RestClient::Request).to have_received(:execute).with(hash_including(method: :post)) }
      end
    end
  end
end
