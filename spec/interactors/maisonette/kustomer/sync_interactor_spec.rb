# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maisonette::Kustomer::SyncInteractor, :vcr do
  subject(:interactor) { described_class.call(kustomer_entity: kustomer_order) }

  let(:kustomer_order) { create(:kustomer_order) }

  before do
    allow(Maisonette::Config).to receive(:fetch).and_call_original
    kustomer_api_key = Maisonette::Config.fetch('kustomer.api_key')

    allow(Maisonette::Config).to receive(:fetch).with('kustomer.api_key').and_return('ABC') if kustomer_api_key.nil?
  end

  describe '#call' do
    it 'returns success' do
      expect(interactor).to be_a_success
    end

    it 'update request information' do
      expect(kustomer_order.last_request_payload).to eq({})

      interactor

      expect(kustomer_order.last_request_payload).not_to eq({})
    end

    it 'returns result information' do
      interactor

      expect(interactor.result).to be_kind_of RestClient::Response
    end

    context 'with Maisonette::Kustomer::Entity.webhook_path' do
      let(:webhook_path) { 'http://kustomer.com/api/fake_webhook' }
      let(:result) { OpenStruct.new code: 200, body: '{}' }

      before do
        allow(Maisonette::Kustomer::Order).to receive(:webhook_path).and_return(webhook_path)
        allow(RestClient::Request).to receive(:execute).and_return(result)
      end

      it 'retrieve the webhook_path from kustomer_entity' do
        interactor

        expect(RestClient::Request).to have_received(:execute).with(
          hash_including(
            url: webhook_path,
            payload: kustomer_order.reload.payload.to_json
          )
        )
      end
    end

    context 'with Maisonette::Kustomer::Entity.webhook_path' do
      let(:webhook_path) { nil }

      before do
        allow(Maisonette::Kustomer::Order).to receive(:webhook_path).and_return(webhook_path)
      end

      it 'fails' do
        expect(interactor).not_to be_a_success
      end

      it 'returns error for missing kustomer API key' do
        expect(interactor.error).to eq 'Missing Webhook path for kustomer class Maisonette::Kustomer::Order'
      end
    end

    context 'when server response with rate_limit error' do
      let(:response) do
        instance_double(
          RestClient::Response,
          body: 'Rate limit error',
          code: 429,
          headers: { 'x-ratelimit-reset' => (Time.current + 1.minute).strftime('%s') }
        )
      end

      before do
        allow(RestClient::Request).to receive(:execute).and_return(response)
      end

      it 'fails' do
        expect(interactor).not_to be_a_success
      end

      it 'returns rate_limit_error' do
        expect(interactor.rate_limit_error).to be_present
      end
    end

    context 'when kustomer api key is not provided' do
      before do
        allow(Maisonette::Config).to receive(:fetch).with('kustomer.api_key').and_return(nil)
      end

      it 'fails' do
        expect(interactor).not_to be_a_success
      end

      it 'returns error for missing kustomer API key' do
        expect(interactor.error).to eq 'Missing Kustomer API Key'
      end
    end

    context 'when payload creation raises an exception' do
      let(:message) { 'undefined method `maisonette_sku` for nil:NilClass' }
      let(:exception) { NoMethodError.new message }

      before do
        allow(Sentry).to receive(:capture_exception_with_message)
        allow(kustomer_order).to receive(:payload).and_raise(exception)
      end

      it 'raises error' do
        expect { interactor }.to raise_error(::Maisonette::Kustomer::PreparePayloadException)
      end
    end

    context 'when request execution raises' do
      before { allow(RestClient::Request).to receive(:execute).and_raise(exception) }

      context 'with RestClient::ExceptionWithResponse' do
        let(:response) { instance_double(RestClient::Response, body: 'body', code: 600) }
        let(:exception) { RestClient::ExceptionWithResponse.new response }

        it 'sets body and code on result' do
          expect(interactor.result.body).to eq 'body'
          expect(interactor.result.code).to eq 600
        end
      end

      context 'with SocketError' do
        let(:exception) { SocketError.new 'body' }

        it 'sets body and code on result' do
          expect(interactor.result.body).to eq 'body'
          expect(interactor.result.code).to eq 500
        end
      end

      context 'with StandardError' do
        before { allow(Sentry).to receive(:capture_exception_with_message) }

        let(:exception) { StandardError.new 'body' }

        it 'sets body and code on result' do
          expect(interactor.result.body).to eq 'body'
          expect(interactor.result.code).to eq 500
        end

        it 'sends the exception on Sentry' do
          interactor

          expect(Sentry).to have_received(:capture_exception_with_message).with(exception)
        end
      end
    end
  end
end
