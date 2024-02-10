# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Return Authorization API', type: :request do
    let(:current_api_user) { order.user }
  let(:spree_api_key) { current_api_user&.spree_api_key }
  let(:headers) { { 'Authorization': "Bearer #{spree_api_key}", 'accept': 'application/json' } }
  let(:order) { create :shipped_order, line_items_count: 3 }
  let(:return_authorizations) { [return_auth] }
  let(:return_auth) { create :return_authorization, order: order }

  before do
    return_authorizations
    order.inventory_units.each_with_index do |unit, i|
      item = create(:return_item, return_authorization: return_auth, inventory_unit: unit, amount: 12)
      item.update(additional_tax_total: 4) if i.odd?
    end
    do_request
  end

  describe '/api/returns/:number' do
    let(:do_request) { get "/api/returns/#{return_auth.number}", headers: headers }

    it 'returns a 200' do
      expect(status).to eq 200
    end

    it 'returns the correct attributes' do
      expect(json_response).to have_attributes %w[
        number created_at reason state
        order ship_address bill_address return_items payments
        refunded_total amount
      ]
      json_response['return_items'].each do |item|
        expect(item.keys).to include 'brand_slug', 'product_slug'
      end
    end

    context 'when a non admin user tries to view another user\'s rma' do
      let(:current_api_user) { create :user }

      it 'can not see another user\'s rma' do
        expect(status).to eq 404
      end
    end

    context 'when the user is an admin' do
      let(:current_api_user) { create :admin_user }

      it 'can see any order' do
        expect(status).to eq 200
      end
    end

    context 'when there is no current_api_user' do
      let(:current_api_user) { nil }

      it 'returns a 401' do
        expect(status).to eq 401
      end
    end

    context 'when no return authorization is found' do
      let(:do_request) { get '/api/returns/bad1234', headers: headers }

      it 'returns a 404' do
        expect(status).to eq 404
      end
    end
  end

  describe '/api/returns/mine' do
    let(:do_request) { get '/api/returns/mine', headers: headers }
    let(:headers) { { 'Authorization': "Bearer #{spree_api_key}", 'accept': 'application/json' } }
    let(:spree_api_key) { order.user.spree_api_key }

    let(:order) { create :shipped_order, line_items_count: 3 }

    it_behaves_like 'mine'

    context 'when fetching a user return authorization history' do
      let(:return_auth) { create :return_authorization, order: order }

      it 'returns a 200' do
        expect(status).to eq 200
      end

      it 'returns the correct attributes' do
        expect(json_response[:return_authorizations].first).to have_attributes %w[
          number created_at return_amount order_number state
        ]
      end

      it 'returns the order_number correctly' do
        expect(json_response[:return_authorizations].first[:order_number]).to eq order.number
      end

      it 'returns the sum of all return items amount + additional tax' do
        total = return_auth.reload.return_items.sum(&:amount) + return_auth.return_items.sum(&:additional_tax_total)
        expect(json_response[:return_authorizations].first[:return_amount]).to eq total.to_s
      end

      context 'when there are multiple' do
        let(:return_authorizations) { [return_auth, return_auth_future, return_auth_past] }
        let(:return_auth_future) { create :return_authorization, order: order, created_at: Time.current + 1.day }
        let(:return_auth_past) { create :return_authorization, order: order, created_at: Time.current - 1.day }

        it 'returns the newest ones first' do
          expect(json_response[:return_authorizations].first[:number]).to eq return_auth_future.number
        end
      end
    end
  end
end
