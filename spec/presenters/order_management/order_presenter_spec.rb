# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::OrderPresenter do
  describe '#payload' do
    let(:address) do
      create(
        :address,
        address1: '123 1st Street',
        city: 'New York',
        state_code: 'NY',
        country_iso_code: 'US',
        zipcode: '12345'
      )
    end
    let(:order) do
      create(
        :completed_order_with_totals,
        number: 'ORD12345',
        billing_address: address,
        channel: 'order_channel',
        is_gift: false
      )
    end
    let(:payload) { described_class.new(order).payload }

    it 'returns the order payload' do # rubocop:disable RSpec/ExampleLength
      expected_payload = {
        Order_Number__c: 'ORD12345',
        Pricebook2Id: '01s4W000000oj5uQAA',
        Status: 'Draft',
        EffectiveDate: order.completed_at.iso8601,
        BillingStreet: '123 1st Street',
        BillingCity: 'New York',
        BillingState: 'New York',
        BillingPostalCode: '12345',
        BillingCountry: 'US',
        Channel__c: 'order_channel',
        Is_Gift__c: false,
        Gift_Email__c: nil,
        Gift_Message__c: nil,
        Guest_Checkout__c: order.guest_checkout?,
        AccountId: '@{refAcc.id}',
        OrderReferenceNumber: 'ORD12345',
        Commercial_ID__c: 'ORD12345',
        Environment__c: 'test',
        SalesChannelId: '0bI1b0000008OaOEAU',
        OrderedDate: order.created_at.iso8601
      }

      expect(payload).to eq(expected_payload)
    end

    context 'when it is a gifted order' do
      before do
        order.update(
          is_gift: true,
          gift_email: 'gift.giver@gmail.com',
          gift_message: 'This is a wonderful gift for you!'
        )
      end

      it 'returns the order payload with gift info' do
        expect(payload).to include Is_Gift__c: order.is_gift
        expect(payload).to include Gift_Email__c: order.gift_email
        expect(payload).to include Gift_Message__c: order.gift_message
      end
    end
  end
end
