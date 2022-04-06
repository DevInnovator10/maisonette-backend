# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'returns API', type: :request do
  include_context 'with Narvar context'

  describe 'POST /api/narvar/returns' do
    subject(:described_request) { post '/api/narvar/returns', headers: headers, params: params }

    let(:headers) do
      { 'Authorization': "Bearer #{user.spree_api_key}", 'Accept': 'application/json' }
    end
    let(:params) { return_payload }
    let(:json_response) { JSON.parse(response.body) }
    let(:role_name) { 'narvar' }
    let(:user) { create(:user, :with_role, role_name: role_name).tap(&:generate_spree_api_key!) }
    let(:order) { create(:shipped_order, line_items_count: 3) }

    before do
      Spree::ReturnReason.find_or_create_by name: 'Other', mirakl_code: 'OTHER'
      described_request
    end

    context 'with an invalid api key' do
      let(:user) { create(:user, :with_role, role_name: 'narvar').tap { |user| user.spree_api_key = '!!!' } }

      it 'returns a failure' do
        expect(response.status).to eq 401
      end
    end

    context 'with non-existing order' do
      let(:params) { { 'order_number': '!!!' } }

      it 'returns a failure' do
        expect(response.status).to eq 404
        expect(json_response.fetch('status')).to eq 'FAILURE'
        expect(json_response.fetch('error')).not_to be_empty
        expect(Spree::ReturnAuthorization.count).to be_zero
      end
    end

    context 'with an invalid payload' do
      let(:params) { { 'order_number': order.number } }

      it 'returns a failure' do
        expect(response.status).to eq 422
        expect(json_response.fetch('status')).to eq 'FAILURE'
        expect(json_response.fetch('error')).not_to be_empty
        expect(Spree::ReturnAuthorization.count).to be_zero
      end
    end

    context 'with a valid payload' do
      it 'makes a successful request' do

        described_request

        expect(response.status).to eq 201
        expect(json_response.fetch('status')).to eq 'SUCCESS'
        expect(Spree::ReturnAuthorization.count).to eq 1
        expect(Spree::ReturnAuthorization.last.order.number).to eq order.number
      end
    end

    context 'when the role is not narvar' do
      let(:role_name) { 'not_narvar' }

      it 'returns a 401' do
        expect(response.status).to eq 401
        expect(Spree::ReturnAuthorization.count).to be_zero
      end
    end
  end
end
