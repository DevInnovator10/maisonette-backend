# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Jifiti::JifitiGateway do
  subject { described_class.new }

  let(:order) { create(:order) }

  describe '#can_capture?' do
    let(:payment) { create(:payment, order: order, state: state) }
    let(:state) { 'checkout' }

    context "when order doesn't come from jifiti" do
      it { is_expected.not_to be_can_capture(payment) }
    end

    context 'when order comes from jifiti' do
      let(:order) do
        create(:order, :jifiti, special_instructions: "external_source: Jifiti Registry\r\n jifiti_order_id: 148734")
      end

      context 'with payment in state checkout' do
        let(:state) { 'checkout' }

        it { is_expected.to be_can_capture(payment) }
      end

      context 'with payment in state pending' do
        let(:state) { 'pending' }

        it { is_expected.to be_can_capture(payment) }
      end

      context 'with payment in state failed' do
        let(:state) { 'failed' }

        it { is_expected.not_to be_can_capture(payment) }
      end
    end
  end

  describe '#can_void?' do
    let(:payment) { create(:payment, order: order, state: state) }
    let(:state) { 'checkout' }

    context "when order doesn't come from jifiti" do
      it { is_expected.not_to be_can_void(payment) }
    end

    context 'when order comes from jifiti' do
      let(:order) do
        create(:order, :jifiti, special_instructions: "external_source: Jifiti Registry\r\n jifiti_order_id: 148734")
      end

      context 'with payment in state checkout' do
        let(:state) { 'checkout' }

        it { is_expected.to be_can_void(payment) }
      end

      context 'with payment in state void' do
        let(:state) { 'void' }

        it { is_expected.not_to be_can_void(payment) }
      end
    end
  end

  describe '#capture' do
    subject { described_class.new.capture }

    it { is_expected.to be_success }
  end

  describe '#try_void' do
    let(:original_method) { described_class.new.method(:void) }
    let(:destination_method) { described_class.new.method(:try_void) }

    it 'is an alias of void' do
      expect(original_method.original_name).to eq destination_method.original_name
      expect(original_method.source_location).to eq destination_method.source_location
    end
  end

  describe '#void' do
    subject { described_class.new.void(nil, order_payload) }

    let(:payment) { create(:jifiti_payment) }
    let(:order_payload) { { order_id: "#{order.number}-#{payment.number}" } }
    let(:context) { instance_double('Interactor::Context', success?: true) }

    before do
      allow(Jifiti::RefundShippedOrderInteractor).to receive(:call!).and_return(context)
      allow(Jifiti::RefundNotShippedOrderInteractor).to receive(:call!).and_return(context)
    end

    it { is_expected.to be_success }

    context 'when shipment_state is not shipped' do
      subject(:described_method) { described_class.new.void(nil, order_payload) }

      it 'calls RefundNotShippedOrderInteractor' do
        described_method

        expect(Jifiti::RefundNotShippedOrderInteractor)
          .to have_received(:call!)
          .with(order: order, amount: payment.amount, mirakl_order_line_reimbursement: nil)
      end
    end

    context 'when shipment_state is shipped' do
      subject(:described_method) { described_class.new.void(nil, order_payload) }

      let(:order) { create(:order, shipment_state: 'shipped') }

      it 'calls RefundShippedOrderInteractor' do
        described_method

        expect(Jifiti::RefundShippedOrderInteractor)
          .to have_received(:call!)
          .with(order: order, amount: payment.amount)
      end
    end
  end

  describe '#credit' do
    subject { described_class.new.credit(amount_in_cents, nil, order_payload) }

    let(:amount) { 9.99 }
    let(:amount_in_cents) { (amount * 100).to_i }
    let(:payment) { create(:jifiti_payment, order: order) }
    let(:order_payload) { { originator: originator } }
    let(:context) { instance_double('Interactor::Context', success?: true) }
    let(:originator) { create(:refund, payment: payment, amount: amount) }

    before do
      allow(Jifiti::RefundShippedOrderInteractor).to receive(:call!).and_return(context)
      allow(Jifiti::RefundNotShippedOrderInteractor).to receive(:call!).and_return(context)
    end

    it { is_expected.to be_success }

    context 'when shipment_state is not shipped' do
      subject(:described_method) { described_class.new.credit(amount_in_cents, nil, order_payload) }

      it 'calls RefundNotShippedOrderInteractor' do
        described_method

        expect(Jifiti::RefundNotShippedOrderInteractor)
          .to have_received(:call!)
          .with(order: order, amount: amount, mirakl_order_line_reimbursement: nil)
      end
    end

    context 'when shipment_state is shipped' do
      subject(:described_method) { described_class.new.credit(amount_in_cents, nil, order_payload) }

      let(:order) { create(:order, shipment_state: 'shipped') }

      it 'calls RefundShippedOrderInteractor' do
        described_method

        expect(Jifiti::RefundShippedOrderInteractor)
          .to have_received(:call!)
          .with(order: order, amount: amount)
      end
    end
  end
end
