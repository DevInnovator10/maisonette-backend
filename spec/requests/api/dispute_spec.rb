# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dispute API', type: :request do
    let(:sample_notification) { { 'bt_signature': '123', 'bt_payload': '456' } }
  let(:headers) { { Accept: 'application/json' } }
  let(:do_request) { post '/api/dispute', headers: headers, params: sample_notification }
  let(:context) { Interactor::Context.new(message: 'success!') }

  describe 'POST /api/dispute' do
    context 'when the payment exists' do
      before { allow(Braintree::DisputeInteractor).to receive_messages(call: context) }

      it 'returns a 200' do
        do_request
        expect(status).to eq 200
      end

      it 'calls Easypost::TrackerInteractor.call' do
        do_request
        expect(Braintree::DisputeInteractor).to have_received(:call).with(bt_signature: '123',
                                                                          bt_payload: '456')
      end
    end

    context 'when the spree_payment does not exist' do
      let(:context) { Interactor::Context.new(missing_payment: '12345', message: 'Missing payment') }

      before do
        allow(Braintree::DisputeInteractor).to receive_messages(call: context)
        allow(Sentry).to receive(:capture_message)
      end

      it 'calls Easypost::TrackerInteractor.call' do
        do_request
        expect(Sentry).to have_received(:capture_message).with('Missing payment', extra: { context: context.to_h })
      end
    end

    context 'when the interactor receives bad params' do
      before do
        allow(Braintree::DisputeInteractor).to receive_messages(call: context)
        allow(context).to receive_messages(success?: false)
      end

      it 'returns a 400' do
        do_request
        expect(response.status).to eq 400
      end
    end
  end
end
