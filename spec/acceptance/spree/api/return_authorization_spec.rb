# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.resource 'Return Authorizations', type: :acceptance do
  let(:user) { order.user }
  let(:bearer) { "Bearer #{user.spree_api_key}" }

  let(:order) { create :shipped_order, user: create(:user) }
  let(:rma) { create :return_authorization, order: order }
  let(:return_item) { create :return_item, return_authorization: rma, inventory_unit: order.inventory_units.first }

  get '/api/returns/:number' do
    let(:number) { return_item.return_authorization.number }

    explanation 'Get a single user return authorziation'

    header 'Authorization', :bearer
    header 'Accept', 'application/json'

    example_request 'returns a 200' do
      expect(status).to eq 200
    end

    context 'when current_api_user is admin' do
      let(:user) { create(:admin_user) }

      example_request 'Can get another user\'s return authorization' do
        expect(status).to eq 200
      end
    end

    context 'when the current_api_user is not admin' do
      let(:user) { create(:user) }

      example_request 'returns a 404' do
        expect(status).to eq 404
      end
    end
  end

  get '/api/returns/mine' do
    explanation 'Get user return authorizations'

    header 'Authorization', :bearer
    header 'Accept', 'application/json'

    before { return_item }

    example_request 'Gets the user\'s return authorizations' do
      expect(status).to eq 200
    end
  end
end
