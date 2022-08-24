# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Subscriber API', type: :request do
  let(:headers) { { 'Accept': 'application/json', 'Authorization': "Bearer #{spree_api_key}" } }
  let(:spree_api_key) { user.spree_api_key }
  let(:params) { {} }
  let(:default_list_id) { FFaker::Lorem.characters 6 }

  let(:user) { create :user }
  let(:admin_user) { create :admin_user }
  let(:subscriber) { create :subscriber, user: user, list_id: default_list_id }
  let(:id) { subscriber.id }

  before do
    allow(Maisonette::Config).to receive(:fetch).with('legacy_url').and_call_original
    allow(Maisonette::Config).to receive(:fetch).with('klaviyo.default_list_id').and_return default_list_id
  end

  describe 'GET /api/subscribers' do
    let(:do_request) { get '/api/subscribers', headers: headers, params: params }
    let(:spree_api_key) { admin_user.spree_api_key }
    let(:subscribed) { create_list :subscriber, 3 }
    let(:unsubscribed) { create_list :subscriber, 3 }

    before { subscribed && unsubscribed }

    it 'returns a 200' do
      do_request
      expect(status).to eq 200
    end

    it 'returns all of the subscribers' do
      do_request
      expect(json_response[:subscribers].map { |x| x[:id] }).to match_array((subscribed + unsubscribed).map(&:id))
    end

    context 'when using pagination' do
      before { subscribed && unsubscribed }

      it 'can see a paginated list of subscribers' do
        do_request
        expect(json_response[:count]).to eq((subscribed + unsubscribed).length)
        expect(json_response[:current_page]).to eq 1
        expect(json_response[:pages]).to eq 1
      end

      it 'can control the page through a parameter' do
        get '/api/subscribers', headers: headers, params: { page: 40 }
        expect(json_response[:current_page]).to eq 40
      end

      it 'can control the page size through a parameter' do
        get '/api/subscribers', headers: headers, params: { per_page: 2 }
        expect(json_response[:per_page]).to eq 2
      end
    end

    context 'when querying results' do
      let(:params) { { q: { user_id_eq: user.id } } }

      before { subscriber && subscribed && do_request }

      it 'can query the results by user_id ' do
        expect(json_response[:count]).to eq 1
        expect(json_response[:subscribers].all? { |wl| wl[:user_id] == user.id }).to be true
      end
    end

    context 'when viewing as a non admin' do
      let(:spree_api_key) { create(:user).spree_api_key }

      it 'returns a 401' do
        do_request
        expect(status).to eq 401
      end
    end

    context 'when not logged in' do
      let(:spree_api_key) { nil }

      it 'returns a 401' do
        do_request
        expect(status).to eq 401
      end
    end
  end

  describe 'POST /api/subscribers' do
    let(:do_request) { post '/api/subscribers', headers: headers, params: params }
    let(:params) { { subscriber: { email: email, first_name: 'Chuck', last_name: 'Berry' } } }
    let(:email) { user.email }

    context 'when not logged in' do
      before { do_request }

      context 'when not providing a list_id' do
        it 'uses the default list_id' do
          expect(json_response[:list_id]).to eq default_list_id
        end
      end

      context 'when providing an alternate list_id' do
        let(:params) { { subscriber: { list_id: 'foo' } } }

        it 'uses the provided list id' do
          expect(status).to eq 201
          expect(json_response[:list_id]).to eq 'foo'
        end
      end
    end

    context 'when logged in' do
      let(:headers) { super().merge('Authorization': "Bearer #{spree_api_key}") }

      before { do_request }

      it 'returns a 201' do
        expect(status).to eq 201
      end

      it 'returns the created object' do
        expect(json_response).to have_attributes %w[
          id user_id email first_name last_name source status created_at phone
        ]
      end

      it 'sets the user id' do
        expect(json_response[:user_id]).to eq user.id
      end

      context 'when not providing a list_id' do
        it 'uses the default list_id' do
          expect(json_response[:list_id]).to eq default_list_id
        end
      end

      context 'when providing an alternate list_id' do
        let(:params) { { subscriber: { list_id: 'foo' } } }

        it 'uses the provided list id' do
          expect(status).to eq 201
          expect(json_response[:list_id]).to eq 'foo'
        end
      end
    end

    context 'when a subscriber with that email exists already' do
      context 'when subscriber is subscribed and synced' do
        let(:subscriber) { create :subscriber, :subscribed_and_synced, :with_user, user: user, source: 'baz' }
        let(:params) { { subscriber: { email: subscriber.user.email } } }

        before do
          allow(Maisonette::Subscriber).to receive(:find_by).with(email: subscriber.user.email).and_return subscriber
          allow(subscriber).to receive(:update!).and_call_original
        end

        it 'does not modify the record' do
          do_request
          expect(subscriber).not_to have_received(:update!)
        end

        context 'when an attribute changes' do
          let(:params) { { subscriber: { email: subscriber.user.email, source: 'foo' } } }

          it 'updates the source' do
            expect { do_request }.to change { subscriber.reload.source }.from('baz').to 'foo'
            expect(subscriber).to have_received(:update!)
            expect(status).to eq 201
          end
        end
      end

      context 'when the subscriber is not subscribed' do
        let(:subscriber) { create :subscriber, :with_user, :unsubscribed, user: user, source: 'baz' }
        let(:params) { { subscriber: { email: email, source: 'bar' } } }

        it 'subscribes the user' do
          expect { do_request }.to change { subscriber.reload.status }.from('unsubscribed').to 'subscribed'
          expect(status).to eq 201
        end

        it 'can update the attributes of the subscription' do
          expect { do_request }.to change { subscriber.reload.source }.from('baz').to 'bar'
          expect(status).to eq 201
        end
      end
    end

    context 'when not logged in' do
      let(:spree_api_key) { nil }
      let(:params) { { subscriber: { email: email, first_name: 'Chuck', last_name: 'Berry' } } }

      before { do_request }

      it 'returns a 201' do
        expect(status).to eq 201
      end

      it 'returns the created object' do
        expect(json_response[:email]).to eq email
        expect(json_response).to have_attributes %w[
          id user_id email first_name last_name source status created_at
        ]
      end

      context 'when a user with the provided email exists' do
        it 'sets the user_id to the associated user id' do
          expect(json_response[:user_id]).to eq user.id
        end
      end

      context 'when a user with the provided email does not exist' do
        let(:email) { FFaker::Internet.email }

        it 'does not set the user_id' do
          expect(json_response[:user_id]).to be_nil
        end
      end
    end

    context 'when unsuccessful create' do
      let(:params) { {} }

      it 'returns a 422' do
        do_request
        expect(status).to eq 422
      end
    end
  end

  describe 'PATCH /api/subscribers/:id' do
    let(:do_request) { patch "/api/subscribers/#{id}", headers: headers, params: params }
    let(:params) { { subscriber: { first_name: new_name } } }
    let(:new_name) { FFaker::Name.first_name }

    before { do_request }

    context 'when not logged in' do
      let(:spree_api_key) { nil }

      it 'returns a 401' do
        expect(status).to eq 401
      end
    end

    context 'when trying to update the subscriber of another user' do
      let(:spree_api_key) { create(:user).spree_api_key }

      it 'returns a 401' do
        expect(status).to eq 401
      end
    end

    context 'when updating your own subscriber' do
      context 'when successful' do
        it 'returns a 200' do
          expect(status).to eq 200
          expect(json_response[:first_name]).to eq new_name
        end

        context 'when updating the list_id' do
          let(:params) { { subscriber: { list_id: 'foo' } } }

          it 'returns a 200' do
            expect(status).to eq 200
            expect(json_response[:list_id]).to eq 'foo'
          end
        end
      end

      context 'when unsuccessful' do
        let(:params) { { subscriber: { email: FFaker::Internet.email } } }

        it 'returns a 422' do
          expect(status).to eq 422
        end

        it 'returns the correct error' do
          error = json_response[:errors][:email]
          expect(error).not_to be_blank
          expect(error).to include 'does not match user email address'
        end

        context 'when trying to update a subscriber that does not exist' do
          let(:id) { 0 }

          it 'returns a 404' do
            expect(status).to eq 404
          end
        end
      end
    end

    context 'when updating as an admin' do
      let(:spree_api_key) { admin_user.spree_api_key }

      it 'can update subscriber of other users' do
        expect(status).to eq 200
        expect(json_response[:id]).to eq subscriber.id
        expect(json_response[:first_name]).to eq new_name
      end

      context 'when trying to update a subscriber that does not exist' do
        let(:id) { 0 }

        it 'returns a 404' do
          expect(status).to eq 404
        end
      end
    end
  end

  describe 'DELETE /api/subscribers/:id' do
    let(:do_request) { delete '/api/subscribers', params: params, headers: headers }

    let(:default_list_subscriber) { create :subscriber, user: user, list_id: default_list_id }
    let(:other_list_subscriber) { create :subscriber, user: user, list_id: 'foo' }

    let(:spree_api_key) { nil }

    before do
      default_list_subscriber
      other_list_subscriber
      do_request
    end

    context 'without the list_id' do
      let(:params) { { subscriber: { email: user.email } } }

      it 'unsubscribes the subscriber associated with the default list' do
        expect(default_list_subscriber.reload).not_to be_subscribed
        expect(other_list_subscriber.reload).to be_subscribed
      end
    end

    context 'with the list_id' do
      let(:params) { { subscriber: { email: user.email, list_id: 'foo' } } }

      it 'unsubscribes the correct subscriber' do
        expect(default_list_subscriber.reload).to be_subscribed
        expect(other_list_subscriber.reload).not_to be_subscribed
      end
    end
  end
end
