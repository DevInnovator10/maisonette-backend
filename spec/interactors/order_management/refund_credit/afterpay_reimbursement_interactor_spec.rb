# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::RefundCredit::AfterpayReimbursementInteractor do
  subject(:interactor) { described_class.call(interactor_context) }

  let(:interactor_context) { {} }

  before do
    allow(Sentry).to receive(:capture_exception_with_message)
  end

  describe '#call' do
    context 'without reimbursement_method' do
      let(:interactor_context) { {} }

      it { is_expected.to be_a_success }
    end

    context 'with reimbursement_method != afterpay' do
      let(:interactor_context) { { reimbursement_method: 'not_afterpay' } }

      it { is_expected.to be_a_success }

      it "doesn't create the refund" do
        expect { interactor }.not_to change(Spree::Refund, :count)
      end
    end

    context 'when reimbursement_method == afterpay' do
      let(:interactor_context) { { reimbursement_method: 'afterpay' } }

      context 'without reimbursement' do
        it { is_expected.to be_failure }

        it 'returns the error' do
          expect(interactor.error).to eq 'Missing reimbursement'
        end
      end

      context 'with reimbursement' do
        let(:payment) { create(:payment, amount: 20, order: reimbursement.order) }
        let(:refund_notes) { 'Reimbursement note' }
        let(:interactor_context) do
          {
            reimbursement_method: 'afterpay',
            amount: 10.00,
            reimbursement: reimbursement,
            notes: refund_notes,
            transaction_id: 'BT-111',
            refund_reason: refund_reason,
            payment_number: payment.number,
          }
        end
        let(:reimbursement) { create(:reimbursement) }
        let(:refund_reason) { create(:refund_reason, name: 'Cancellation') }

        it { is_expected.to be_a_success }

        it 'creates a new refund' do
          expect { interactor }.to change(Spree::Refund, :count).by(1)

          expect(interactor.refund).to have_attributes(
            payment_id: payment.id,
            amount: 10,
            refund_reason_id: refund_reason.id,
            transaction_id: 'BT-111',
            reimbursement: reimbursement
          )
        end

        context 'when reimbursement and payment are not related to the same order' do
          let(:payment) { create(:payment, amount: 20) }

          it { is_expected.to be_a_failure }

          it "doesn't create the refund" do
            expect(interactor.error).to eq 'Payment and Reimbursement are not under the same order'
            expect(Sentry).to have_received(:capture_exception_with_message)
          end
        end

        context 'when refund creation fails' do
          let(:exception) { StandardError.new('failed') }

          before { allow(Spree::Refund).to receive(:create!).and_raise(exception) }

          it { is_expected.to be_failure }

          it 'fails with error' do
            expect(interactor.error).to eq "Refund creation for payment #{payment.number} failed with failed"
          end

          it 'sends the exception on Sentry' do
            interactor

            expect(Sentry).to have_received(:capture_exception_with_message).with(
              exception,
              hash_including(extra: { context: interactor_context })
            )
          end
        end
      end
    end
  end
end
