# frozen_string_literal: true

require 'rails_helper'
require 'solidus_afterpay/testing_support/factories'

RSpec.describe SolidusAfterpay::PaymentSource::Status, type: :model do
  let(:described_class) { SolidusAfterpay::PaymentSource }

  describe '#can_refund?' do
    subject(:can_refund?) { source.can_refund?(payment) }

    let(:source) { build :afterpay_payment_source }
    let(:payment) { build :afterpay_payment, response_code: response_code }
    let(:response_code) { 'afterpay_response_code' }
    let(:payment_method) { payment.payment_method }

    let(:gateway) { instance_double SolidusAfterpay::Gateway }
    let(:afterpay_payment) { { paymentState: payment_state } }
    let(:payment_state) {}

    before do
      allow(gateway).to receive(:find_payment).with(order_id: response_code).and_return(afterpay_payment)

      allow(payment_method).to receive(:gateway).and_return(gateway)
    end

    context 'when there is no response_code' do
      let(:response_code) {}

      it 'returns false' do
        expect(can_refund?).to eq false
      end
    end

    context 'when Afterpay::BaseError is thrown' do
      let(:payment_state) { 'CAPTURED' }

      before do
        allow(gateway).to receive(:find_payment).and_raise(Afterpay::BaseError.new(nil))
      end

      it 'returns false' do
        expect(can_refund?).to eq false
      end
    end

    context 'when the payment state is CAPTURE_DECLINED' do
      let(:payment_state) { 'CAPTURE_DECLINED' }

      it 'returns false' do
        expect(can_refund?).to eq false
      end
    end

    context 'when the payment state is CAPTURED' do
      let(:payment_state) { 'CAPTURED' }

      it 'returns true' do
        expect(can_refund?).to eq true
      end
    end

    context 'when the payment state is PARTIALLY_CAPTURED' do
      let(:payment_state) { 'PARTIALLY_CAPTURED' }

      it 'returns true' do
        expect(can_refund?).to eq true
      end
    end
  end
end
