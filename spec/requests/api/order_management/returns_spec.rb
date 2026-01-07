# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Returns API', type: :request do
  let(:headers) { { 'Accept': 'application/json', 'Authorization': "Bearer #{spree_api_key}" } }
  let(:params) { {} }

  describe 'POST /api/oms/returns' do
    let(:do_request) { post '/api/oms/returns', headers: headers, params: params }
    let(:params) { {} }

    context 'when viewing as a non admin' do
      let(:spree_api_key) { user.spree_api_key }
      let(:user) { create(:user) }

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

    context 'when logged in with salesforce role' do
      let(:spree_api_key) { salesforce_user.spree_api_key }
      let(:salesforce_user) { create(:user, :with_oms_role) }
      let(:return_authorization) { create(:return_authorization) }

      before do
        allow(OrderManagement::CreateReturnAuthorizationInteractor).to receive(:call).and_return(
          interactor_result
        )
      end

      context 'when interactor return success' do
        let(:interactor_result) do
          double( # rubocop:disable RSpec/VerifiedDoubles
            Interactor::Context, success?: true, return_authorization: return_authorization
          )
        end
        let(:return_reason) { create(:return_reason) }
        let(:params) do
          {
            return: {
              total: 'total_amount',
              tracking_url: 'tracking_url',
              info: [{
                order_item_summary_ref: '',
                quantity: 10,
                return_reason_external_id: OrderManagement::Entity.find_by(order_manageable: return_reason).to_gid_param
              }],
            }
          }
        end

        it 'provides the braintree data to interactor' do
          do_request

          expect(status).to eq 201
          expect(OrderManagement::CreateReturnAuthorizationInteractor).to have_received(:call).with(
            hash_including(
              :total,
              current_user: salesforce_user,
              tracking_url: 'tracking_url',
              info: array_including(
                hash_including(:order_item_summary_ref, :quantity, :return_reason_external_id)
              )
            )
          )
        end
      end

      context 'when interactor fails' do
        let(:params) do
          { return: { info: nil } }
        end
        let(:interactor_result) do
          double(Interactor::Context, success?: false, error: 'error_message') # rubocop:disable RSpec/VerifiedDoubles
        end

        it 'returns an unprocessable_entity' do
          do_request

          expect(status).to eq 422
        end

        it 'returns error' do
          do_request

          expect(json_response[:error]).to eq 'error_message'
        end
      end
    end
  end
end
