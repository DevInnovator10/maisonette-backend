# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::PaymentSourcePresenter do
  describe '#payload' do
    context 'when payment source is a store credit' do
      it 'returns store credit payload' do
        source = 'Store Credit'

        expected_payload = {
          attributes: { type: 'DigitalWallet' },
          Type: 'Store Credit',
          AccountId: '@{refAcc.id}',
          Status: 'Active',
          ProcessingMode: 'External',
          GatewayToken: '2020',
          PaymentGatewayId: '0b01b0000004C9DAAU'
        }

        expect(described_class.new(source).payload).to eq(expected_payload)
      end
    end

    context 'when payment source is a braintree source' do
      it 'returns braintree source payload' do
        source = SolidusPaypalBraintree::Source.new(payment_type: 'CreditCard')
        allow(source).to receive(:card_type).and_return('Visa')
        allow(source).to receive(:expiration_year).and_return('2021')
        allow(source).to receive(:expiration_month).and_return('5')
        allow(source).to receive(:last_4).and_return('4703')

        expected_payload = {
          attributes: { type: 'CardPaymentMethod' },
          CardCategory: 'CreditCard',
          AccountId: '@{refAcc.id}',
          Status: 'Active',
          ProcessingMode: 'External',
          CardType: 'Visa',
          ExpiryYear: '2021',
          ExpiryMonth: '5',
          CardLastFour: '4703',
          PaymentGatewayId: '0b01b0000000001AAA'
        }

        expect(described_class.new(source).payload).to eq(expected_payload)
      end

      context 'when card type is MasterCard' do
        it 'returns card type as Master Card' do
          source = SolidusPaypalBraintree::Source.new(payment_type: 'CreditCard')
          allow(source).to receive(:card_type).and_return('MasterCard')
          allow(source).to receive(:last_4).and_return('2701')
          expect(described_class.new(source).payload[:CardType]).to eq('Master Card')
          expect(described_class.new(source).payload[:CardLastFour]).to eq('2701')
        end
      end

      context 'when card category is PaypalAccount' do
        let(:source) { SolidusPaypalBraintree::Source.new(payment_type: 'PayPalAccount') }
        let(:paypal_account) { Braintree::PayPalAccount._new(:gateway, default: true) }
        let(:payload) { described_class.new(source).payload }

        before do
          allow(source).to receive(:braintree_payment_method).and_return(paypal_account)
          allow(source).to receive(:last_4).and_return('4703')
        end

        it 'returns Paypal as card type' do
          expect(payload).to match hash_including(CardCategory: 'CreditCard', CardType: 'Paypal')
        end

        it 'does not return last four credit card numbers' do
          expect(payload['CardLastFour']).to be_nil
          expect(source).not_to have_received(:last_4)
        end
      end
    end

    context 'when payment source is a afterpay source' do
      subject(:outcome) { described_class.new(source).payload }

      let(:source) { ::SolidusAfterpay::PaymentSource.new }
      let(:payment) { build_stubbed(:jifiti_payment, response_code: '100101952340') }
      let(:expected) do
        {
          attributes: { type: 'DigitalWallet' },
          Type: 'AfterPay',
          GatewayToken: '2020',
          PaymentGatewayId: '0b01b0000004C9SAAU',
          Status: 'Active',
          AccountId: '@{refAcc.id}',
          AfterPay_Order_ID__c: '100101952340',
          ProcessingMode: 'External'
        }
      end

      before { source.payments << payment }

      it 'returns afterpay source payload' do
        expect(outcome).to eq(expected)
      end
    end
  end
end
