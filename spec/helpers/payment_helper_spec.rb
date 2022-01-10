# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentHelper do
    let(:credit_card_source) { create :solidus_paypal_braintree_source, :with_credit_card }
  let(:paypal_source) { create :solidus_paypal_braintree_source, :paypal_billing_agreement }

  describe '#order_payment_label' do
    let(:payment_label) { helper.order_payment_label(order) }

    let(:order) { create :order }
    let(:payment) { build_stubbed :payment, source: credit_card_source }

    before { allow(helper).to receive(:payment_label) }

    describe 'when there are no valid payments' do
      it 'calls payment_label' do
        order.payments.clear
        payment_label
        expect(helper).not_to have_received(:payment_label)
      end
    end

    describe 'when there is a valid payment' do
      before { allow(order.payments).to receive(:valid).and_return([payment]) }

      it 'calls payment_label' do
        payment_label
        expect(helper).to have_received(:payment_label).once
      end
    end
  end

  describe '#source_name' do
    subject { helper.source_name(payment) }

    context 'when there is no payment source' do
      let(:payment) { build :payment, source: nil }

      it { is_expected.to eq '' }
    end

    context 'when there is a braintree credit card source' do
      let(:payment) { build :payment, source: credit_card_source }

      it { is_expected.to eq credit_card_source.payment_type.underscore.humanize }
    end

    context 'when there is a braintree paypal source' do
      let(:payment) { build :payment, source: paypal_source }

      it { is_expected.to eq paypal_source.payment_type.underscore.humanize }
    end

    context 'when there is a store credit payment' do
      let(:payment) { build :store_credit_payment }

      it { is_expected.to eq 'Store Credit' }
    end
  end

  describe '#payment_description' do
    subject { helper.payment_description(payment) }

    let(:order) { create :order }

    context 'when there is no source' do
      let(:payment) { build_stubbed :payment, order: order }

      before { allow(payment).to receive(:source).and_return nil }

      it { is_expected.to eq '' }
    end

    context 'when there is a paypal email source' do
      let(:payment) { build_stubbed :payment, order: order, source: paypal_source, amount: 10.0 }
      let(:payments) { [payment] }
      let(:email) { FFaker::Internet.email }

      before do
        allow(order.payments).to receive(:valid).and_return payments
        allow(paypal_source).to receive(:email).and_return email
      end

      it { is_expected.to eq email }

      context 'when there are multiple payments' do
        let(:payments) { [payment, build_stubbed(:payment, order: order, source: paypal_source)] }

        it { is_expected.to eq email + " (#{payment.display_amount})" }

        context 'when email source is nil' do
          let(:email) { nil }

          it { is_expected.to be_blank }
        end
      end
    end

    context 'when there is a credit card source' do
      let(:payment) { build_stubbed :payment, order: order, source: credit_card_source }
      let(:payments) { [payment] }
      let(:card_type) { 'Visa' }
      let(:last_digits) { 4444 }

      before do
        allow(order.payments).to receive(:valid).and_return payments
        allow(credit_card_source).to receive(:card_type).and_return card_type
        allow(credit_card_source).to receive(:last_digits).and_return last_digits
      end

      it { is_expected.to eq "#{card_type.upcase}, Ending in #{last_digits}" }

      context 'when card_type and last_digits are nil' do
        let(:card_type) { nil }
        let(:last_digits) { nil }

        it { is_expected.to be_nil }

        context 'when there are multiple payments' do
          let(:payments) { [payment, build_stubbed(:payment, order: order, source: paypal_source)] }

          it { is_expected.to eq "(#{payment.display_amount})" }
        end
      end
    end
  end
end
