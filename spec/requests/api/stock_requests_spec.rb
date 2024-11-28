# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Stock Request API', type: :request do
  let(:headers) { { 'Accept': 'application/json' } }
  let(:params) { {} }

  describe 'POST /api/stock_requests' do
    let(:do_request) { post '/api/stock_requests', headers: headers, params: params }

    let(:email) { FFaker::Internet.email }
    let(:variant) { create :variant }
    let(:stock_request) { Maisonette::StockRequest.find_by(email: email, variant: variant) }

    let(:params) { { stock_request: { email: email, variant_id: variant.id } } }

    context 'when creating is successful' do
      it 'returns a 201' do
        do_request
        expect(status).to eq 201
      end

      it 'creates a stock request with the correct attributes' do
        do_request
        expect(stock_request).not_to be_nil
      end

      context 'when passing additional attributes' do
        let(:params) do
          { stock_request: { email: email, variant_id: variant.id, state: 'queued', sent_at: Time.current } }
        end

        it 'does not allow you to set the state' do
          do_request
          expect(stock_request.state).to eq 'requested'
        end

        it 'does not allow you to set the sent_at' do
          do_request
          expect(stock_request.sent_at).to be_nil
        end
      end
    end

    context 'when the email and variant are already present' do
      before { create(:stock_request, email: email, variant_id: variant.id) }

      it 'returns the error and the error message' do
        do_request
        expect(status).to eq 422
        expect(json_response[:success]).to eq false
        expect(json_response[:message]).to eq 'Email is already on the waitlist for this product.'
      end
    end

    context 'when not successful' do
      let(:params) { { stock_request: { email: 'foo', variant_id: variant.id } } }

      it 'returns a 422' do
        do_request
        expect(status).to eq 422
      end

      it 'returns the error message' do
        do_request
        expect(json_response[:success]).to eq false
        expect(json_response[:message]).to include 'Email is invalid'
      end
    end
  end
end
