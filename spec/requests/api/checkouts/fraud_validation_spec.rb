# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/checkouts/', type: :request do
  describe 'PUT complete' do
    subject(:do_complete) { put spree.complete_api_checkout_path(order.to_param), headers: headers }

    let(:headers) { { 'X-Spree-Order-Token' => order.guest_token } }
    let(:order) { create(:order_ready_to_complete) }
    let(:validation_context) { instance_double Interactor::Context, success?: validation_success? }
    let(:validation_success?) {}

    before do
      allow(Forter::ValidationInteractor).to receive(:call).and_return(validation_context)
    end

    context 'when validation is declined' do
      let(:validation_success?) { false }

      it 'brings back the order at payment level' do
        expect { do_complete }.to change { order.reload.state }.from('confirm').to('payment')

        expect(json_response).to(
          match hash_including(error: 'The order could not be transitioned. Please fix the errors and try again.')
        )
        expect(order.payments.valid).to be_empty
      end
    end

    context 'when the validation is accepted' do
      let(:validation_success?) { true }

      it 'completes the order' do
        expect { do_complete }.to change { order.reload.state }.from('confirm').to('complete')
        expect(json_response).not_to(match hash_including('error'))
        expect(order.payments.completed).not_to be_empty
      end
    end
  end

  describe '#update' do
    subject(:update) { put spree.api_checkout_path(order.to_param), headers: headers, params: params }

    let(:order) { create :order_ready_to_complete }
    let(:headers) { { 'X-Spree-Order-Token' => order.guest_token, 'HTTP_CLIENT_IP' => '127.0.0.1' } }
    let(:params) {}

    it 'saves the client ip address to the order' do
      expect { update }.to change { order.reload.last_ip_address }.from(nil).to('127.0.0.1')
    end

    context 'when there are order params' do
      let(:params) { { order: { forter_connection_info: { user_agent: 'user_agent' } } } }

      it 'saves the client ip address to the order' do
        expect { update }.to change { order.reload.last_ip_address }.from(nil).to('127.0.0.1')
        expect(order.forter_connection_info['user_agent']).to eq 'user_agent'
      end
    end
  end
end
