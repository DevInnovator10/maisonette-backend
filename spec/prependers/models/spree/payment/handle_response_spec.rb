# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Payment::HandleResponse, type: :model do
    let(:described_class) { Spree::Payment }

  describe 'handle_response' do
    subject(:handle_response) { payment.send(:handle_response, response, success_state, failure_state) }

    let(:payment) { described_class.new }
    let(:response) do
      ActiveMerchant::Billing::Response.new(false,
                                            'some error',
                                            {},
                                            authorization: response_code)
    end
    let(:response_code) { 'dkf3xydm' }
    let(:success_state) {}
    let(:failure_state) { :failure }

    before do
      allow(payment).to receive_messages(record_response: true, failure: true, gateway_error: true)
    end

    it 'calls super' do
      handle_response
      expect(payment).to have_received(:record_response)
      expect(payment).to have_received(:failure)
      expect(payment).to have_received(:gateway_error)
    end

    it 'saves the response_code to the payment' do
      expect { handle_response }.to change(payment, :response_code).from(nil).to(response_code)
    end
  end
end
