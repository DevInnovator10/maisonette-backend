# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.resource 'Wallet payment sources', type: :acceptance do
  let(:user) { create(:user).tap(&:generate_spree_api_key!) }
  let(:bearer) { "Bearer #{user.spree_api_key}" }

  header 'Accept', 'application/json'
  header 'Authorization', :bearer

  get '/api/wallet_payment_sources' do
    before { create :wallet_payment_source, user: user }

    example_request 'Get user wallet payment sources' do
      expect(status).to eq 200
    end
  end

  delete '/api/wallet_payment_sources/:id' do
    let(:wallet_payment_source) { create :wallet_payment_source, user: user }
    let(:id) { wallet_payment_source.id }

    example_request 'Remove the payment from the user wallet' do

      expect(status).to eq 204
    end
  end

  post '/api/wallet_payment_sources/:id/default' do
    let(:wallet_payment_source) { create :wallet_payment_source, user: user }
    let(:id) { wallet_payment_source.id }

    example_request 'Set a wallet payment source as the default user payment method' do
      expect(status).to eq 204
    end
  end
end
