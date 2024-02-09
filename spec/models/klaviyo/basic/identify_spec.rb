# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Klaviyo::Basic::Identify do
    let(:endpoint) { Klaviyo::Basic::Identify::ENDPOINT }
  let(:base_payload) { { 'token' => public_api_key } }

  let(:client) { instance_double 'DummyClass', get_request: response, public_api_key: public_api_key }

  let(:public_api_key) { FFaker::Lorem.characters(128) }
  let(:klaviyo_api_url) { FFaker::Internet.http_url }

  let(:properties) { { email: email } }
  let(:email) { FFaker::Internet.email }
  let(:id) { rand(9999) }

  let(:response) { instance_double RestClient::Response, body: '1', code: 200 }

  def encoded(payload)
    json_payload = Oj.generate(payload)
    Addressable::URI.parse(Base64.encode64(json_payload)).to_s.gsub(/\n/, '')
  end

  describe '#identify' do
    subject(:identify) { client.identify(properties) }

    before { client.extend described_class }

    context 'when successful' do
      before { identify }

      it 'returns true' do
        expect(identify).to be_truthy
      end

      context 'when sending special identify properties' do
        let(:properties) { { email: email, id: id, first_name: 'foo', region: 'NYC', title: 'bar' } }
        let(:payload) do
          base_payload.reverse_merge(
            'properties' => {
              '$email' => email, '$id' => id, '$first_name' => 'foo', '$region' => 'NYC', '$title' => 'bar'
            }
          )
        end

        it 'translates special params' do
          expect(client).to have_received(:get_request).with(endpoint, data: encoded(payload))
        end
      end

      context 'when sending additional attributes' do
        let(:properties) { { email: email, custom1: 'foo', custom2: 'bar' } }
        let(:payload) do
          base_payload.reverse_merge('properties' => { '$email' => email, 'custom1' => 'foo', 'custom2' => 'bar' })
        end

        it 'adds everything to the payload' do
          expect(client).to have_received(:get_request).with(endpoint, data: encoded(payload))
        end
      end
    end

    context 'when unsuccessful' do
      before { allow(response).to receive(:body).and_return '0' }

      it 'returns false' do
        expect(identify).to be_falsey
      end

      context 'when omitting the email or id' do
        let(:properties) { { event: 'foo' } }

        it 'throws an error' do
          expect { identify }.to raise_exception Klaviyo::Api::KlaviyoError
          expect(client).not_to have_received(:get_request)
        end
      end
    end
  end
end
