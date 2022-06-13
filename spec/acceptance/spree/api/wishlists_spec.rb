# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.resource 'Wishlists', type: :acceptance do
  header 'Accept', 'application/json'
  header 'Authorization', :bearer

  let(:bearer) { "Bearer #{spree_api_key}" }
  let(:spree_api_key) { user.spree_api_key }
  let(:user) { create :user }

  let(:wishlist_with_products) { create :wishlist, product_count: 3, user: user }

  get '/api/wishlists' do
    explanation 'Get all wishlists, only accessible to admin users'
    parameter :user_id_eq, 'Anything accessible by ransack can be passed in as query params', scope: :q

    let(:spree_api_key) { create(:admin_user).spree_api_key }

    before { create_list :wishlist, 10 }

    example_request 'Get all wishlists' do
      expect(status).to eq 200
    end
  end

  get '/api/wishlists/:id' do
    explanation 'Get a single wishlist, accessible by owner of the list, or if it is public'

    let(:id) { wishlist_with_products.id }

    example_request 'Get a single wishlist' do
      expect(status).to eq 200
    end
  end

  post '/api/wishlists' do
    explanation 'Create a wishlist. Any user can create their own wishlist, admins can create wishlists for others.'

    parameter :name,
              "The first wishlist created is given the name \"My Wishlist\". \
              Subsequent wishlists must be given a new name.",
              scope: :wishlist,
              required: true
    parameter :user_id,
              "User ID must match that of the current_api_user unless the current_api_user is an admin. \
              User ID will be inferred from the current_api_user unless explicitly provided",
              scope: :wishlist
    parameter :is_default,
              "The first wishlist created will automatically be set to default. Subsequent lists will have is_default \
              set to false. If you pass is_default true it will set all other user wishlists to is_default: false.",
              scope: :wishlist
    parameter :is_public, scope: :wishlist
    parameter :wished_products_attributes,
              "You can create a new wishlist with wished products in one step by passing them as nested attributes. \
              This should be an array of objects.",
              scope: :wishlist
    parameter :variant_id,
              'Pass the variant id for a wished product as a nested attribute.',
              scope: [:wishlist, :wished_products_attributes]
    parameter :quantity,
              'Pass the quantity for a wished product as a nested attribute',
              scope: [:wishlist, :wished_products_attributes]
    parameter :remark,
              'Pass the remark for the specific wished product as a nested attribute.',
              scope: [:wishlist, :wished_products_attributes]

    let(:name) { nil }
    let(:user_id) { user.id }
    let(:is_default) { true }
    let(:is_public) { false }

    example_request 'Create a wishlist' do
      expect(status).to eq 201
    end
  end

  patch '/api/wishlists/:id' do
    explanation 'Update a wishlist. Users can update their own wishlists, admins can create wishlists for others.'

    parameter :name,
              "The first wishlist created is given the name \"My Wishlist\". \
              Subsequent wishlists must be given a new name.",
              scope: :wishlist,
              required: true
    parameter :user_id,
              "User ID must match that of the current_api_user unless the current_api_user is an admin. \
              User ID will be inferred from the current_api_user unless explicitly provided",
              scope: :wishlist
    parameter :is_default,
              "The first wishlist created will automatically be set to default. Subsequent lists will have is_default \
              set to false. If you pass is_default true it will set all other user wishlists to is_default: false.",
              scope: :wishlist
    parameter :is_public, scope: :wishlist

    let(:name) { 'Another Wishlist' }
    let(:user_id) { user.id }
    let(:is_default) { true }
    let(:is_public) { false }
    let(:id) { wishlist_with_products.id }

    example_request 'Update a wishlist' do
      expect(status).to eq 200
    end
  end

  delete '/api/wishlists/:id' do
    explanation 'Destroy a wishlist. Users can destroy their own wishlists, admins can destroy any.'

    let(:id) { user.default_wishlist.id }

    example_request 'Delete a wishlist' do
      expect(status).to eq 204
    end
  end

  get '/api/wishlists/mine' do
    explanation 'Get a users wishlists'

    before do
      create_list :wishlist, 3, user: create(:user)
      create_list :wishlist, 10, user: user
    end

    example_request 'Get my wishlists' do
      expect(status).to eq 200
      expect(json_response[:wishlists].length).to eq 10
      expect(json_response[:wishlists].all? { |wl| wl[:user_id] == user.id }).to be true
    end
  end

  get '/api/wishlist' do
    explanation 'Get a user\'s default wishlist. This will create a default wishlist if one does not exist.'

    before { wishlist_with_products }

    example_request 'Get my default wishlist' do
      expect(status).to eq 200
      expect(json_response[:id]).to eq wishlist_with_products.id
    end
  end
end
