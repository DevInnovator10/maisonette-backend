# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Klaviyo::Client::DataPrivacy do
  let(:data_privacy) { described_class.new(client: client) }
  let(:client) { instance_double Klaviyo::Client, private_api_key: private_api_key }

  let(:private_api_key) { FFaker::Lorem.characters(64) }

  let(:body) { { user: { email: FFaker::Internet.email } } }
  let(:json_string) { Oj.generate body }

  let(:authorized_headers) { { 'api-key' => client.private_api_key } }

  let(:deletion_request_endpoint) { 'api/v2/data-privacy/deletion-request' }

  describe '#deletion_request' do
    subject(:deletion_request) { data_privacy.deletion_request(data) }

    let(:data) { { email: FFaker::Internet.email } }
    let(:response) { instance_double RestClient::Response, body: json_string, code: 200 }

    before do
      allow(data_privacy).to receive(:post_request).and_return response
      allow(data_privacy).to receive(:authorized_headers).and_return authorized_headers
    end

    it 'sends a deletion request' do
      deletion_request
      expect(data_privacy).to have_received(:post_request)
    end

    context 'when sending a single email' do
      before { deletion_request }

      it 'sends the correct payload' do
        expect(data_privacy).to have_received(:post_request).with(deletion_request_endpoint, data, authorized_headers)
      end
    end

    context 'when successful' do
      it 'returns true' do
        expect(deletion_request).to eq true
      end
    end

    context 'when unsuccessful' do
      context 'without an email' do
        let(:data) { { email: nil } }

        it 'throws a klaviyo error' do
          error_message = I18n.t(:invalid_deletion_request_data, scope: 'errors.klaviyo.data_privacy')
          expect { deletion_request }.to raise_exception Klaviyo::Api::KlaviyoError, error_message
        end
      end

      context 'when unsuccessful response from klaviyo' do
        let(:error_message_body) { Oj.generate(detail: 'error message') }
        let(:response) { instance_double RestClient::Response, body: error_message_body, code: 400 }

        it 'returns an error message' do
          expect(deletion_request).to eq 'error message'
        end
      end
    end
  end
end
