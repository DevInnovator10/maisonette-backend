# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  let(:headers) { { 'Accept': 'application/json', 'Authorization': "Bearer #{spree_api_key}" } }
  let(:spree_api_key) { user.spree_api_key }

  describe 'POST /api/users' do
    context 'when there is a current order' do
      let(:post_create) { post '/api/users', headers: headers, params: params }
      let(:headers) { { 'Accept': 'application/json', 'X-Spree-Order-Token': order.token } }
      let(:params) do
        {
          user: {
            email: 'email@example.com',
            first_name: 'firstname',
            last_name: 'lastname',
            password: 'password',
            password_confirmation: 'password'
          },
          order_number: order.number
        }
      end
      let(:order) { create :order_with_line_items, user: nil }

      it 'associates the current order to the registered user' do
        post_create
        expect(order.reload.user).to eq Spree::User.find_by!(email: 'email@example.com')
      end
    end
  end

  describe '/api/users/mine' do
    include_context 'when a user has wallet payment sources'

    let(:do_request) { get '/api/users/mine', headers: headers }

    it_behaves_like 'mine'

    it 'returns a 200' do
      do_request
      expect(status).to eq 200
    end

    it 'has the required user attributes' do
      do_request
      expect(json_response).to have_attributes %w[
        id first_name last_name email
        subscribed addresses payment_sources
      ]
    end

    context 'when returning addresses' do
      let(:address_json) { json_response[:addresses] }
      let(:default_address) { create :address }
      let(:json_default_address) { address_json.detect { |a| a[:default] = 'true' } }

      before do
        user.addresses.push(*create_list(:address, 3))
        user.default_address = default_address
        do_request
      end

      it 'has the required address attributes' do
        expect(address_json.first).to have_attributes [:default]
      end

      it 'returns the default address correctly' do
        expect(json_default_address[:id]).to eq default_address.id
      end

      it 'returns the correct country' do
        address_json.each do |address|
          country_name = Spree::Country.find(address[:country_id]).name
          expect(address[:country][:name]).to eq country_name
          expect(address[:country]).to have_attributes [:id, :iso_name, :iso, :iso3, :name, :numcode]
        end
      end
    end

    context 'when returning payment sources' do
      let(:payment_json) { json_response[:payment_sources] }

      before { wallet_credit_card && wallet_applepay && wallet_paypal && do_request }

      it 'has the attributes for a credit card' do
        expect(payment_json.first).to have_attributes %w[id source default]
      end

      it 'has the attributes for the wallet source payment source' do
        expect(payment_json.first['source']).to have_attributes %w[
          payment_type token cc_type last_digits month year
        ]
      end

      it 'returns default true for the correct address' do
        expect(payment_json.detect { |x| x['default'] }[:source][:id]).to eq wallet_credit_card.payment_source_id
      end
    end
  end

  describe 'PUT /api/users/:id/unsubscribe' do
    let(:do_request) { put "/api/users/#{id}/unsubscribe", headers: headers }
    let(:user) { create(:subscriber, :with_user).user }
    let(:id) { user.id }

    context 'when successful' do
      it 'returns a 200' do
        do_request
        expect(status).to eq 200
      end

      it 'unsubscribes a user that is subscribed' do
        expect(user.subscribed?).to be true
        do_request
        expect(user.reload.subscribed?).to be false
      end

      it 'returns the user object with the correct subscribed attribute' do
        expect(user.subscribed?).to be true
        do_request
        expect(json_response[:id]).to eq user.id
        expect(json_response[:subscribed]).to eq false
      end

      context 'when a user is already unsubscribed' do
        let(:unsubscribed) { create(:subscriber, :unsubscribed_and_synced, :with_user) }
        let(:user) { unsubscribed.user }

        it 'does not change a subscriber' do
          allow(user.subscriber).to receive(:unsubscribed!)

          do_request

          expect(user.subscriber).to eq unsubscribed
          expect(user.subscriber.status).to eq 'unsubscribed_and_synced'
          expect(user.subscriber).not_to have_received(:unsubscribed!)
        end
      end
    end

    context "when trying to subscribe another user's subscriber" do
      context 'when an admin user' do
        let(:spree_api_key) { create(:admin_user).spree_api_key }

        it 'returns a 200' do
          do_request
          expect(status).to eq 200
        end
      end

      context 'when a regular user' do
        let(:spree_api_key) { create(:user).spree_api_key }

        it 'returns a 404' do
          do_request
          expect(status).to eq 404
        end
      end

      context 'when logged out' do
        let(:spree_api_key) { nil }

        it 'returns a 404' do
          do_request
          expect(status).to eq 404
        end
      end
    end
  end

  describe 'PUT /api/users/:id/subscribe' do
    let(:do_request) { put "/api/users/#{id}/subscribe", headers: headers }
    let(:user) { create :user }
    let(:id) { user.id }

    context 'when successful' do
      it 'returns a 200' do
        do_request
        expect(status).to eq 200
      end

      it 'subscribes a user that is not subscribed' do
        expect(user.subscribed?).to be false
        do_request
        expect(user.reload.subscribed?).to be true
      end

      it 'does not change a subscription that is already subscribed' do
        subscriber = create :subscriber, :subscribed_and_synced, user: user
        allow(user.subscriber).to receive(:subscribed!)

        do_request

        expect(user.subscriber).to eq subscriber
        expect(user.subscriber.status).to eq 'subscribed_and_synced'
        expect(user.subscriber).not_to have_received(:subscribed!)
      end

      it 'returns the user object with the subscribed attribute' do
        do_request
        expect(json_response[:id]).to eq user.id
        expect(json_response[:subscribed]).to eq true
      end
    end

    context "when trying to subscribe another user's subscriber" do
      context 'when an admin user' do
        let(:spree_api_key) { create(:admin_user).spree_api_key }

        it 'returns a 200' do
          do_request
          expect(status).to eq 200
        end
      end

      context 'when a regular user' do
        let(:spree_api_key) { create(:user).spree_api_key }

        it 'returns a 404' do
          do_request
          expect(status).to eq 404
        end
      end

      context 'when logged out' do
        let(:spree_api_key) { nil }

        it 'returns a 404' do
          do_request
          expect(status).to eq 404
        end
      end
    end
  end
end
