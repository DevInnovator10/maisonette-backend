# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Api::Jifiti::OrdersController, type: :controller do
  render_views
  let(:current_api_user) { create(:user, :with_role, role_name: role_name).tap(&:generate_spree_api_key!) }
  let(:role_name) { 'jifiti' }
  let(:jifiti_order_controller) { jifiti_order_controller.new }
  let(:params) do
    {
      "order": {
        "line_items": [
          {
            "variant_id": '57777',
            "quantity": '1',
            "vendor_name": 'Lindsey Berns'
          }
        ],
        "ship_address": {
          "firstname": 'richard',
          "lastname": 'twena',
          "address1": '55 washington street',
          "city": 'Brooklyn',
          "phone": '1234567890',
          "zipcode": '11201',
          "state_id": '3534',
          "country_id": '232'
        },
        "email": 'richard.twena@maisonette.com',
        "special_instructions": "external_source : Jifiti Registry\r\n jifiti_order_id: 148734"
      },
      "format": 'json'
    }
  end

  let(:normalized_params) do
    { 'email' => 'richard.twena@maisonette.com',
      'special_instructions' => "external_source : Jifiti Registry\r\n jifiti_order_id: 148734",
      'line_items_attributes' => [{ 'variant_id' => '57777', 'quantity' => '1', 'vendor_name' => 'Lindsey Berns' }],
      'ship_address_attributes' => { 'firstname' => 'richard',
                                     'lastname' => 'twena',
                                     'address1' => '55 washington street',
                                     'city' => 'Brooklyn',
                                     'phone' => '1234567890',
                                     'zipcode' => '11201',
                                     'state_id' => '3534',
                                     'country_id' => '232' } }
  end

  let(:context) { Interactor::Context.new(order: order) }
  let(:order) { create :order_ready_to_ship }

  describe 'create' do
    before do
      stub_authentication!
      allow(Jifiti::ProcessOrderInteractor).to receive_messages(call!: context)

      post :create, params: params
    end

    it 'calls Jifiti::ProcessOrderInteractor.call!' do
      expect(Jifiti::ProcessOrderInteractor).to have_received(:call!).with(order_params: normalized_params)
    end

    it 'response with order json' do
      expect(response.status).to eq 201
      expect(json_response['number']).to eq order.number
    end

    context 'when the role is not jifiti' do
      let(:role_name) { 'not_jifiti' }

      it 'returns a 401' do
        expect(response.status).to eq 401
        expect(Jifiti::ProcessOrderInteractor).not_to have_received(:call!)
      end
    end
  end
end
