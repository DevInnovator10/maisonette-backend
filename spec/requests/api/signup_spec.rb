# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  describe '#signup' do
    let(:email) { 'test@example.com' }
    let(:password) { 'test123' }
    let(:password_confirmation) { password }
    let(:first_name) { 'foo' }
    let(:last_name) { 'bar' }
    let(:params) do
      {
        user: {
          email: email,
          password: password,
          password_confirmation: password,
          first_name: first_name,
          last_name: last_name
        }
      }
    end

    context 'when it is a valid new user' do
      let(:new_user) { Spree::User.find(json_response[:id]) }

      before { post '/api/users', params: params }

      it 'creates a user and return its spree token' do
        expect(status).to eq 201
        expect(headers['Authorization']).to be_present
        expect(headers['Authorization']).to match(/^Bearer .+$/)
      end

      it 'allows first_name and last_name to be passed in' do
        expect(new_user.first_name).to eq first_name
        expect(new_user.last_name).to eq last_name
      end

      context 'when subscribing' do
        let(:params) { super().merge(subscribe: true) }

        it 'creates a subscriber when the parameter is passed' do
          expect(status).to eq 201
          expect(new_user.subscribed?).to be true
        end
      end

      context 'when not subscribing' do
        it 'does not create a subscriber if omitted' do
          expect(status).to eq 201
          expect(new_user.subscribed?).to be false
        end
      end
    end

    context 'when it is an invalid user' do
      context 'when subscribing' do
        let(:params) { super().merge(subscribe: true) }

        it 'creates a subscriber when the parameter is passed' do
          create(:user, email: email)

          post '/api/users', params: params

          expect(status).to eq 422
          expect(json_response['errors']).to include 'Email has already been taken'
        end
      end
    end
  end
end
