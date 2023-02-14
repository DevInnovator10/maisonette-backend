# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Klaviyo::Api::Verbs do
  let(:client) { instance_double 'DummyClass', default_headers: default_headers }

  let(:klaviyo_api_key) { FFaker::Lorem.characters(128) }

  let(:endpoint) { 'api/endpoint' }
  let(:request_url) { Klaviyo::Api::KLAVIYO_API_URL + endpoint }

  let(:default_headers) { { accept: :json, content_type: :json } }
  let(:headers) { {} }
  let(:params) { {} }

  def sanitized(payload)
    Oj.generate payload.deep_stringify_keys
  end

  before { client.extend described_class }

  describe '#get_request' do
    subject(:get_request) { client.get_request(endpoint, params, headers) }

    before do
      allow(RestClient).to receive(:get)
      get_request
    end

    context 'when not specifying headers' do
      context 'when not specifying params' do
        let(:hash) { headers.reverse_merge(default_headers) }

        it 'uses default_headers and does not include params' do
          expect(RestClient).to have_received(:get).with(request_url, hash)
        end
      end

      context 'when specifying params' do
        let(:hash) { default_headers.merge(params: params) }
        let(:params) { { some_key: 'some_value' } }

        it 'uses default_headers and includes the params' do
          expect(RestClient).to have_received(:get).with(request_url, hash)
        end
      end
    end

    context 'when specifying headers' do
      let(:headers) { { accept: :html } }
      let(:expected_headers) { headers.reverse_merge(default_headers) }

      context 'when not specifying params' do
        let(:hash) { expected_headers }

        it 'uses custom headers and includes the params' do
          expect(RestClient).to have_received(:get).with(request_url, hash)
        end
      end

      context 'when specifying params' do
        let(:hash) { expected_headers.merge(params: params) }
        let(:params) { { some_key: 'some_value' } }

        it 'uses default_headers and includes the params' do
          expect(RestClient).to have_received(:get).with(request_url, hash)
        end
      end
    end
  end

  [:patch, :post].each do |verb|
    describe "##{verb}_request" do
      subject(:request) { client.send(method, endpoint, params, headers) }

      let(:method) { "#{verb}_request".to_sym }

      before do
        allow(RestClient).to receive(verb)
        request
      end

      context 'when not specifying headers' do
        context 'when not specifying params' do
          it 'uses default_headers and does not include params' do
            expect(RestClient).to have_received(verb).with(request_url, sanitized(params), default_headers)
          end
        end

        context 'when specifying params' do
          let(:params) { { some_key: 'some_value' } }

          it 'uses default_headers and includes the params' do
            expect(RestClient).to have_received(verb).with(request_url, sanitized(params), default_headers)
          end
        end
      end

      context 'when specifying headers' do
        let(:headers) { { accept: :html } }
        let(:expected_headers) { headers.reverse_merge(default_headers) }

        context 'when not specifying params' do
          it 'uses custom headers and includes the params' do
            expect(RestClient).to have_received(verb).with(request_url, sanitized(params), expected_headers)
          end
        end

        context 'when specifying params' do
          let(:params) { { some_key: 'some_value' } }

          it 'uses default_headers and includes the params' do
            expect(RestClient).to have_received(verb).with(request_url, sanitized(params), expected_headers)
          end
        end
      end
    end
  end

  describe '#delete_request' do
    subject(:delete_request) { client.delete_request(endpoint, payload, headers) }

    let(:endpoint) { delete_endpoint }
    let(:delete_endpoint) { 'api/users/delete' }
    let(:payload) { {} }

    before do
      allow(RestClient::Request).to receive(:execute)
      delete_request
    end

    context 'when not providing headers' do
      it 'sends a request to the provided path with default_headers' do
        args = { method: :delete, url: request_url, payload: sanitized(payload), headers: default_headers }
        expect(RestClient::Request).to have_received(:execute).with(args)
      end
    end

    context 'when providing headers' do
      let(:headers) { { accept: :html } }
      let(:expected_headers) { headers.reverse_merge(default_headers) }

      it 'uses user headers if provided' do
        args = { method: :delete, url: request_url, payload: sanitized(payload), headers: expected_headers }
        expect(RestClient::Request).to have_received(:execute).with(args)
      end
    end
  end
end
