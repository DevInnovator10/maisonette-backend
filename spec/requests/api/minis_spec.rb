# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Minis API', type: :request do
  # instead of taking the values and setting them individually,
  # we could instead calculate the date based off of the information that is given
  # for instance, if a only the year 2019 was given, set the birthdate to jan 1, 2019
  # if a year and a date were given, Feb 2019, we set the date to feb 1, 2019
  # and finally if the full date were given, we would validate and set the date as such

  let(:headers) { { 'Accept': 'application/json', 'Authorization': "Bearer #{spree_api_key}" } }
  let(:params) { {} }
  let(:spree_api_key) { user.spree_api_key }
  let(:admin_user) { create :admin_user }
  let(:user) { create :user }
  let(:mini) { create :mini, user: user }
  let(:id) { mini.id }

  let(:user_minis) { create_list :mini, 3, user: user }
  let(:other_minis) { create_list :mini, 4 }

  describe 'GET /minis' do
    let(:do_request) { get '/api/minis', headers: headers, params: params }
    let(:spree_api_key) { admin_user.spree_api_key }
    let(:params) { {} }

    it 'returns a 200' do
      do_request
      expect(status).to eq 200
    end

    context 'when viewing as a non admin' do
      let(:spree_api_key) { user.spree_api_key }

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

    context 'when using pagination' do
      before { other_minis }

      it 'can see a paginated list of wishlists' do
        do_request
        expect(json_response[:count]).to eq other_minis.length
        expect(json_response[:current_page]).to eq 1
        expect(json_response[:pages]).to eq 1
      end

      it 'returns the minis in the right order' do
        do_request
        expect(json_response[:minis].map { |x| x[:id] }).to eq Maisonette::Mini.order(created_at: :desc).ids
      end

      it 'can control the page through a parameter' do
        get '/api/minis', headers: headers, params: { page: 40 }
        expect(json_response[:current_page]).to eq 40
      end

      it 'can control the page size through a parameter' do
        get '/api/minis', headers: headers, params: { per_page: 2 }
        expect(json_response[:per_page]).to eq 2
      end
    end

    context 'when querying results' do
      let(:params) { { q: { user_id_eq: user.id } } }

      before { user_minis && do_request }

      it 'can query the results by user_id ' do
        expect(json_response[:count]).to eq user_minis.length
        expect(json_response[:minis].all? { |wl| wl[:user_id] == user.id }).to be true
      end
    end
  end

  describe 'GET /api/minis/:id' do
    let(:do_request) { get "/api/minis/#{id}", headers: headers, params: params }

    before { do_request }

    it 'returns a 200' do
      expect(status).to eq 200
    end

    it 'has all attributes on the model' do
      expect(json_response).to have_attributes %w[
        id user_id name birth_year birth_month birth_day gender_boy gender_girl gender_taxons age_range_taxons
      ]
    end

    context 'when viewing a mini that is not yours' do
      let(:spree_api_key) { create(:user).spree_api_key }

      it 'returns a 401' do
        expect(status).to eq 401
      end
    end

    context 'when not logged in' do
      let(:spree_api_key) { nil }

      it 'returns a 401' do
        expect(status).to eq 401
      end
    end
  end

  describe 'PATCH /api/minis/:id' do
    let(:do_request) { patch "/api/minis/#{id}", headers: headers, params: params }
    let(:params) { { mini: { name: new_name } } }
    let(:new_name) { 'Jason Statham' }

    before { do_request }

    context 'when not logged in' do
      let(:spree_api_key) { nil }

      it 'returns a 401' do
        expect(status).to eq 401
      end
    end

    context 'when trying to update the mini of another user' do
      let(:spree_api_key) { create(:user).spree_api_key }

      it 'returns a 401' do
        expect(status).to eq 401
      end
    end

    context 'when updating your own mini' do
      context 'when successful' do
        it 'returns a 200' do
          expect(status).to eq 200
          expect(json_response[:name]).to eq new_name
        end
      end

      context 'when unsuccessful' do
        let(:params) { { mini: { name: nil } } }

        it 'returns a 422' do
          expect(status).to eq 422
        end

        it 'returns the correct error' do
          error = json_response[:errors][:name]
          expect(error).not_to be_blank
          expect(error).to include "can't be blank"
        end

        context 'when trying to update a mini that does not exist' do
          let(:id) { 0 }

          it 'returns a 404' do
            expect(status).to eq 404
          end
        end
      end
    end

    context 'when updating as an admin' do
      let(:spree_api_key) { admin_user.spree_api_key }

      it 'can update minis of other users' do
        expect(status).to eq 200
        expect(json_response[:id]).to eq mini.id
        expect(json_response[:name]).to eq new_name
      end

      context 'when trying to update a mini that does not exist' do
        let(:id) { 0 }

        it 'returns a 404' do
          expect(status).to eq 404
        end
      end
    end
  end

  describe 'POST /api/minis' do
    let(:do_request) { post '/api/minis', headers: headers, params: params }
    let(:params) do
      { mini: { name: 'Chuck', user_id: user.id,
                birth_year: Time.current.year,
                birth_month: Time.current.month,
                birth_day: Time.current.day } }
    end

    context 'when logged in' do
      before { do_request }

      it 'returns a 201' do
        expect(status).to eq 201
      end

      it 'returns the created object' do
        expect(json_response[:user_id]).to eq user.id
        expect(json_response).to have_attributes %w[
          id user_id name birth_year birth_month birth_day gender_boy gender_girl
        ]
      end

      context 'when creating without a user id' do
        let(:params) do
          { mini: { name: 'New Mini', user_id: user.id,
                    birth_year: Time.current.year,
                    birth_month: Time.current.month,
                    birth_day: Time.current.day } }
        end

        it 'returns a 201' do
          expect(status).to eq 201
        end

        it 'creates a new mini for the logged in user' do
          expect(json_response[:user_id]).to eq user.id
        end
      end

      context 'when trying to create a mini for other users' do
        let(:params) { { mini: { user_id: create(:user).id, name: 'Timmy', birth_year: Time.current.year } } }

        it 'returns a 401' do
          expect(status).to eq 401
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

    context 'when not logged in' do
      let(:spree_api_key) { nil }

      it 'returns a 401' do
        do_request
        expect(status).to eq 401
      end
    end

    context 'when logged in as an admin' do
      let(:spree_api_key) { admin_user.spree_api_key }
      let(:params) do
        { mini: { name: 'Larry', user_id: user.id,
                  birth_year: Time.current.year,
                  birth_month: Time.current.month,
                  birth_day: Time.current.day } }
      end

      it 'can create minis for other users' do
        do_request
        expect(status).to eq 201
        expect(json_response[:user_id]).to eq user.id
        expect(json_response[:name]).to eq 'Larry'
      end
    end
  end

  describe 'DELETE /api/minis' do
    let(:do_request) { delete "/api/minis/#{id}", headers: headers }

    before { do_request }

    context 'when a user is deleting their own Mini' do
      it 'is successful' do
        expect(status).to eq 204
        expect(Maisonette::Mini.find_by(id: id)).to be_nil
      end
    end

    context 'when a not logged in user tries to delete a Mini' do
      let(:spree_api_key) { nil }

      it 'returns a 401' do
        expect(status).to eq 401
        expect(Maisonette::Mini.find_by(id: id)).not_to be_nil
      end
    end

    context 'when a user tries to delete a mini of another user' do
      let(:spree_api_key) { create(:user).spree_api_key }

      it 'returns a 401' do
        expect(status).to eq 401
        expect(Maisonette::Mini.find_by(id: id)).not_to be_nil
      end
    end

    context 'when admin' do
      let(:spree_api_key) { create(:admin_user).spree_api_key }

      it 'can delete minis from other users' do
        expect(status).to eq 204
        expect(Maisonette::Mini.find_by(id: id)).to be_nil
      end
    end
  end

  describe 'GET /api/minis/mine' do
    let(:do_request) { get '/api/minis/mine', headers: headers, params: params }
    let(:minis_json) { json_response[:minis] }

    before { user_minis && other_minis }

    it_behaves_like 'mine'

    it 'returns a 200' do
      do_request
      expect(status).to eq 200
    end

    it 'only returns my minis' do
      do_request
      expect(minis_json.count).to eq user.minis.length
      expect(minis_json.all? { |wl| wl[:user_id] == user.id }).to be true
    end

    context 'when filtering by params' do
      let(:params) { { q: { name_eq: new_name } } }
      let(:new_name) { 'Chuck' }

      before { mini.update(name: new_name) }

      it 'can filter by name' do
        do_request
        expect(minis_json.length).to eq 1
        expect(minis_json.first[:name]).to eq new_name
      end
    end
  end
end
