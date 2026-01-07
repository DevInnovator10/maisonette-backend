# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Narvar::Api::Commands::UpdateOrderInteractor, narvar: true do
  describe '#call' do
    subject(:described_method) { described_class.call(params) }

    let(:params) {}

    it { is_expected.to be_failure }
    it { expect(described_method.error).to eq 'Order required' }

    context 'with an order' do
      before do
        response = instance_double(RestClient::Response, body: '{}')
        allow(RestClient::Request).to receive(:execute).and_return(response)
        described_method
      end

      let(:order) { build_stubbed :order }
      let(:params) { { order: order } }

      it { is_expected.to be_failure }
      it { expect(described_method.error).to eq 'Narvar Order required' }

      context 'with an order Narvar updated' do
        let(:order) { build_stubbed :order, narvar_order: build_stubbed(:narvar_order) }

        it { expect(described_method).to be_success }
        it { expect(RestClient::Request).to have_received(:execute).with(hash_including(method: :put)) }
      end
    end
  end
end
