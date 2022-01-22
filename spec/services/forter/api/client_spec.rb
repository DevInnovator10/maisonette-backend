# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forter::Api::Client do
    let(:order) { create :order, number: 'M920354089' }
  let(:client) { described_class }

  describe '#validate_order', vcr: true do
    let(:payload) { YAML.load_file(Rails.root.join('spec/fixtures/forter/validate_order_payload.yml')) }

    context 'when the order is approved' do
      it 'returns approve message' do
        payload[:accountOwner][:email] = 'approve@forter.com'

        expect(client.validate_order(order, payload)).to eq(
          'message' => 'message',
          'action' => 'approve',
          'reasonCode' => 'Test',
          'transaction' => '123456',
          'status' => 'success'
        )
      end
    end

    context 'when the order is declined' do
      it 'returns decline message' do
        payload[:accountOwner][:email] = 'decline@forter.com'

        expect(client.validate_order(order, payload)).to eq(
          'message' => 'message',
          'action' => 'decline',
          'reasonCode' => 'Test',
          'transaction' => '123456',
          'status' => 'success'
        )
      end
    end

    context 'when the order is not reviewed' do
      it 'returns not reviewed message' do
        payload[:accountOwner][:email] = 'notreviewed@forter.com'

        expect(client.validate_order(order, payload)).to eq(
          'message' => 'message',
          'action' => 'not reviewed',
          'reasonCode' => 'Test',
          'transaction' => '123456',
          'status' => 'success'
        )
      end
    end

    context 'when the request fails' do
      it 'returns the error message' do
        payload[:accountOwner][:email] = 'approve@forter.com'
        payload[:orderType] = 'INVALID_TYPE'

        expect(client.validate_order(order, payload)).to eq(
          'status' => 'failed',
          'message' => 'Malformed request',
          'errorsCount' => 1,
          'errors' => [
            { 'message' => 'No enum match for: INVALID_TYPE', 'path' => '#/orderType' }
          ]
        )
      end
    end
  end

  describe '#update_order_status', vcr: true do
    let(:payload) { YAML.load_file(Rails.root.join('spec/fixtures/forter/update_order_status_payload.yml')) }

    context 'when client is approved' do
      it 'returns approved message' do
        expect(client.update_order_status(order, payload)).to eq(
          'message' => 'Transaction #M920354089 status received',
          'status' => 'success'
        )
      end
    end

    context 'when the request fails' do
      it 'returns the error message' do
        payload[:updatedStatus] = 'INVALID_STATUS'

        expect(client.update_order_status(order, payload)).to eq(
          'status' => 'failed',
          'message' => 'Malformed request',
          'errorsCount' => 1,
          'errors' => [
            { 'message' => 'No enum match for: INVALID_STATUS', 'path' => '#/updatedStatus' }
          ]
        )
      end
    end
  end
end
