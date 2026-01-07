# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Store Credits API', type: :request do
  describe '/api/store_credits/mine' do
    let(:store_credit) { create :store_credit }
    let(:spree_api_key) { store_credit.user.spree_api_key }

    let(:do_request) { get '/api/store_credits/mine', headers: headers }
    let(:headers) { { 'Authorization': "Bearer #{spree_api_key}", 'Accept': 'application/json' } }

    it_behaves_like 'mine'

    it 'returns a 200' do
      do_request
      expect(status).to eq 200
    end

    it 'has the required attributes' do
      do_request
      expect(json_response[:count]).to eq 1
      expect(json_response).to have_attributes %w[store_credits current_balance]
      expect(json_response[:store_credits].first).to have_attributes %w[
        created_at category amount amount_used
      ]
    end

    it 'does not return invalidated credits' do
      store_credit.update(invalidated_at: Time.current)
      do_request
      expect(json_response[:count]).to eq 0
      expect(json_response[:store_credits].length).to eq 0
    end
  end
end
