# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::CreateManualRefundOrderAdjustmentInteractor do
  describe '#call' do
    subject(:call) { described_class.call refund: refund, order: order }

    let(:refund) do
      instance_double Spree::Refund, persisted?: persisted?, amount: refund_amount, reason: reason, payment: payment
    end
    let(:refund_amount) { 25.0 }
    let(:order) { instance_double Spree::Order, adjustments: adjustments, recalculate: true }
    let(:adjustments) { class_double Spree::Adjustment, create!: true }
    let(:reason) { instance_double Spree::RefundReason, name: 'Shipping Refund' }
    let(:payment) { instance_double Spree::Payment, number: 'P123546' }

    context 'when the refund is not persisted' do
      let(:persisted?) { false }

      before { call }

      it 'fails the interactor' do
        expect(call).to be_failure
      end

      it 'does not create adjustments' do
        expect(adjustments).not_to have_received(:create!)
      end
    end

    context 'when the refund is persisted' do
      let(:persisted?) { true }
      let(:adjustment_label) do
        "Adjustment due to manual refund: #{reason.name} - #{payment.number}"
      end

      context 'when there are no errors' do
        before { call }

        it 'creates an adjustments' do
          expect(adjustments).to have_received(:create!).with(amount: -refund_amount,
                                                              label: adjustment_label,
                                                              order: order,
                                                              finalized: true)
        end

        it 'recalculates the order' do
          expect(order).to have_received(:recalculate)
        end
      end

      context 'when there are errors' do
        subject(:call) { interactor.call }

        let(:interactor) { described_class.new refund: refund, order: order }
        let(:exception) { StandardError.new 'some adjustment error' }

        before do
          allow(adjustments).to receive(:create!).and_raise(exception)
          allow(interactor).to receive_messages(rescue_and_capture: true)
          allow(interactor.context).to receive(:fail!)

          call
        end

        it 'call rescue_and_capture with the exception and fail' do
          expect(interactor).to have_received(:rescue_and_capture).with(exception)
          expect(interactor.context).to have_received(:fail!).with(error: exception)
        end
      end
    end
  end
end
