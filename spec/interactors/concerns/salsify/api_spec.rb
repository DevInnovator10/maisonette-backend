# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salsify::Api, mirakl: true do
  let(:described_class) { FakeSalsifyApiInteractor }
  let(:base) { described_class.new }
  let(:auth_token) { 'salsify_auth' }
  let(:api_endpoint) { 'salsify_endpoint/api' }
  let(:organization_id) { 'org/123' }
  let(:full_url) { api_endpoint + '/orgs/' + organization_id + api_method }
  let(:headers) { { Authorization: "Bearer #{auth_token}", 'Content-Type' => 'application/json' } }

  before do
    allow(Maisonette::Config).to receive(:fetch).with('salsify.auth_token').and_return(auth_token)
    allow(Maisonette::Config).to receive(:fetch).with('salsify.api_endpoint').and_return(api_endpoint)
    allow(Maisonette::Config).to receive(:fetch).with('salsify.organization_id').and_return(organization_id)
  end

  describe '#get' do
    subject(:get) { base.send :get, api_method }

    let(:api_method) { '/products' }

    context 'when it is successful' do
      let(:response) { instance_double RestClient::Response }

      before { allow(RestClient).to receive_messages(public_send: response) }

      it 'returns a RestClient::Response' do
        expect(get).to eq response
        expect(RestClient).to have_received(:public_send).with(:get, full_url, headers)
        expect(base.context.success?).to eq true
        expect(base.context.error).to be_nil
      end
    end

    context 'when a RestClient exception is thrown' do
      let(:rest_client_exception) { RestClient::ExceptionWithResponse.new response }
      let(:response) { instance_double RestClient::Response, code: 404, body: 'Not Found' }
      let(:error_message) { 'status: 404, message: Not Found' }

      before { allow(RestClient).to receive(:public_send).and_raise(rest_client_exception) }

      it 'returns false' do
        expect(get).to eq false
        expect(base.context.message).to eq error_message
      end
    end

    context 'when SocketError is thrown' do
      let(:socket_error) { SocketError.new 'bad socket!' }
      let(:error_message) { 'message: bad socket!' }

      before { allow(RestClient).to receive(:public_send).and_raise(socket_error) }

      it 'returns false' do
        expect(get).to eq false
        expect(base.context.message).to eq error_message
      end
    end
  end

  describe 'post' do
    subject(:post) { base.send :post, api_method, payload: payload }

    let(:api_method) { '/products' }
    let(:payload) { { some: 'payload' } }

    before do
      allow(base).to receive(:rest_client_call)

      post
    end

    it 'calls rest_client_call with :post' do
      expect(base).to have_received(:rest_client_call).with(:post, api_method, payload: payload)
    end
  end

  describe 'put' do
    subject(:put) { base.send :put, api_method, payload: payload }

    let(:api_method) { '/products/1234' }
    let(:payload) { { some: 'payload' } }

    before do
      allow(base).to receive(:rest_client_call)

      put
    end

    it 'calls rest_client_call with :put' do
      expect(base).to have_received(:rest_client_call).with(:put, api_method, payload: payload)
    end
  end

  describe 'delete' do
    subject(:delete) { base.send :delete, api_method, payload: payload }

    let(:api_method) { '/docs' }
    let(:payload) { { some: 'payload' } }

    before do
      allow(base).to receive(:rest_client_call)

      delete
    end

    it 'calls rest_client_call with :delete' do
      expect(base).to have_received(:rest_client_call).with(:delete, api_method, payload: payload)
    end
  end

  describe '#handle_rest_error' do
    let(:base) { described_class.new }

    context 'when StandardError' do
      let(:exception) { StandardError.new 'foo' }

      before do
        allow(Sentry).to receive(:capture_exception_with_message)

        base.send :handle_rest_error, exception
      end

      it 'captures the exception in Sentry' do
        expect(Sentry).to have_received(:capture_exception_with_message).with(exception)
      end
    end
  end
end

class FakeSalsifyApiInteractor
  include Interactor
  include Salsify::Api
end
