# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.resource 'Stock Requests', type: :acceptance do
    header 'Accept', 'application/json'

  let(:variant_id) { create(:variant).id }
  let(:email) { FFaker::Internet.email }

  post '/api/stock_requests' do
    explanation 'Create a new stock request, accessible without an api key'

    parameter :email, scope: :stock_request, required: true
    parameter :variant_id, scope: :stock_request, required: true

    context 'when successful' do
      example_request 'Create a stock request' do
        expect(status).to eq 201
      end
    end

    context 'when unsuccessful' do
      let(:email) { 'foo' }

      example_request 'With a bad email' do
        expect(status).to eq 422
      end
    end

    context 'when unsuccessful' do
      before { create :stock_request, email: email, variant_id: variant_id }

      example_request 'With a duplicate email and product' do
        expect(status).to eq 422
      end
    end
  end
end
