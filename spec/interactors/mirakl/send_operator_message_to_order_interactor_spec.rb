# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::SendOperatorMessageToOrderInteractor, mirakl: true do
  describe 'hooks' do
    let(:interactor) { described_class.new }

    it 'has before hooks' do
      expect(described_class.before_hooks).to eq [:use_operator_key]
    end
  end

  describe '#call' do
    let(:interactor) do
      described_class.new(mirakl_order_id: mirakl_order_id,
                          message: message,
                          subject: subject,
                          to_customer: to_customer,
                          to_shop: to_shop)
    end

    let(:mirakl_order_id) { 'R2134-A' }
    let(:message) { 'some message' }
    let(:subject) { 'some subject' }
    let(:to_customer) { true }
    let(:to_shop) { true }
    let(:message_payload) do
      { body: message,
        subject: subject,
        to_customer: to_customer,
        to_operator: false,
        to_shop: to_shop }
    end

    before do
      allow(interactor).to receive(:post)

      interactor.call
    end

    it 'sends a post to "/orders/:ORDER_ID/messages"' do
      expect(interactor).to have_received(:post).with("/orders/#{mirakl_order_id}/messages",
                                                      payload: message_payload.to_json)
    end
  end
end
