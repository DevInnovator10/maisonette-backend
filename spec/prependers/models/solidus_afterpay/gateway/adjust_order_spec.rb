# frozen_string_literal: true

require 'rails_helper'
require 'solidus_afterpay/testing_support/factories'

RSpec.describe SolidusAfterpay::Gateway::AdjustOrder do
  let(:described_class) { SolidusAfterpay::Gateway }

  let(:gateway) { described_class.new(options) }
  let(:options) do
    {
      merchant_id: ENV.fetch('AFTERPAY_MERCHANT_ID', 'dummy_merchant_id'),
      secret_key: ENV.fetch('AFTERPAY_SECRET_KEY', 'dummy_secret_key'),
      test_mode: true
    }
  end

  describe '#capture' do
    subject(:response) { gateway.capture(amount, nil, gateway_options) }

    let(:order_token) { '002.8lp05rmle32ja716duf55uugh5a9ftb25g771a6li8j2a3pe' }
    let(:auto_capture) { true }
    let(:payment_source) { build(:afterpay_payment_source, token: order_token) }
    let(:payment_method) { build(:afterpay_payment_method, auto_capture: auto_capture) }
    let(:order) { build(:order_with_line_items) }
    let(:payment) { build(:afterpay_payment, source: payment_source, payment_method: payment_method, order: order) }

    let(:amount) { 5_000 }
    let(:gateway_options) { { originator: payment, currency: 'USD' } }

    context 'with the immediate flow' do
      context 'with an amount less than or equal to the original order total', :vcr do
        it 'captures the afterpay payment with the order_token' do
          is_expected.to be_success
        end
      end

      context 'with an amount greater than the original order total', :vcr do
        let(:amount) { 10_000 }

        it 'returns an unsuccesfull response' do
          is_expected.not_to be_success

        end

        it 'returns the error message from Afterpay in the response' do
          expect(response.message).to eq('Payment schedule checksum mismatch')
        end

        it 'returns the error_code from Afterpay in the response' do
          expect(response.error_code).to eq('invalid_object')
        end
      end
    end
  end
end
