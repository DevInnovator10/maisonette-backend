# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::CreateAppeasementInteractor do
  describe '#call' do
    subject(:call_interactor!) { described_class.call(interactor_context) }

    context 'without any adjustments' do
      let(:interactor_context) { {} }

      it { is_expected.to be_failure }

      it 'returns the error' do
        expect(call_interactor!.error).to eq 'Missing order'
      end
    end

    context 'with adjustment' do
      let(:adjustment_reason) { create(:adjustment_reason) }
      let(:reason_code) { 'REFUND_CODE_1' }
      let(:refund_reason) { create :refund_reason, mirakl_code: reason_code }

      before do
        adjustment_reason
        refund_reason
      end

      context 'when order_item_summary_id is not present' do
        let(:info) do
          [
            {
              order_item_summary_id: 'line_item_1', label: 'Never Worked', amount: 10.0,
              adjustment_reason_external_id: adjustment_reason.to_gid_param
            }
          ]
        end
        let(:refunds) do
          [{ reimbursement_method: 'store_credit', amount: 10.0, reason_code: reason_code }]
        end
        let(:interactor_context) do
          {
            total: 10,
            info: info,
            current_user: create(:user),
            refunds: refunds
          }
        end

        it { is_expected.to be_failure }

        it 'returns the error' do
          expect(call_interactor!.error).to eq 'Missing order'
        end

        context 'when order_item_summary_id is present' do
          let(:order_item_summary) { create(:order_item_summary, order_management_ref: 'line_item_1') }
          let(:reimbursement_interactor) { OrderManagement::RefundCredit::StoreCreditReimbursementInteractor }

          before do
            order_item_summary

            create(:store_credit_category, name: reimbursement_interactor::STORE_CREDIT_CATEGORY_NAME)
            create(:store_credit_type, name: reimbursement_interactor::STORE_CREDIT_TYPE_NAME)
          end

          it { is_expected.to be_success }

          it 'creates the reimbursement' do
            expect { call_interactor! }.to change { Spree::Reimbursement.count }.by(1)

            expect(call_interactor!.reimbursement).to have_attributes(
              reimbursement_status: 'reimbursed',
              total: 10
            )
          end

          it 'creates a new adjustment' do
            expect { call_interactor! }.to change { Spree::Adjustment.count }.by(1)

            expect(Spree::Adjustment.last).to have_attributes(
              order: call_interactor!.reimbursement.order,
              source: call_interactor!.reimbursement,
              amount: 10,
              label: 'Never Worked',
              included: true,
              adjustment_reason: adjustment_reason,
              adjustable: order_item_summary.summarable
            )
          end

          it 'creates the adjustment related to the line_item' do
            expect { call_interactor! }.to change { Spree::Adjustment.count }.by(1)
          end

          context 'with refunds for giftcard' do
            let(:refunds) do
              [
                {
                  reimbursement_method: 'gift_card',
                  amount: 9.0,
                  gift_card_email: 'admin@example.com',
                  reason_code: reason_code
                }
              ]
            end

            it { is_expected.to be_success }
          end

          context 'with refunds for braintree' do
            let(:payment) { create(:payment, amount: 15, order: order_item_summary.summarable.order) }
            let(:refunds) do
              [
                {
                  reimbursement_method: 'braintree',
                  amount: 10.0,
                  payment_number: payment.number,
                  transaction_id: 'ABC123',
                  reason_code: reason_code
                }
              ]
            end

            let(:interactor_context) do
              {
                total: 10,
                refund_reason: create(:refund_reason),
                current_user: create(:user),
                info: info,
                refunds: refunds
              }
            end

            it { is_expected.to be_success }
          end

          context 'when adjustment creation fails' do
            before { allow(Spree::Adjustment).to receive(:create!).and_raise(StandardError, 'Error') }

            it { expect { call_interactor! }.to raise_error(StandardError) }
          end

          context 'when refunds array is empty' do
            let(:refunds) { [] }

            it { is_expected.to be_failure }

            it 'is expected return the error' do
              is_expected.to have_attributes(error: 'No Refund/Credit created')
            end
          end

          context 'when the refund creation raises an error' do
            before do
              allow(OrderManagement::RefundCredit::CreateOrganizer).to receive(:call).and_raise(StandardError)
            end

            it { expect { call_interactor! }.to raise_error(StandardError) }

            it "doesn't create reimbursement and adjustment" do
              expect { -> { call_interactor! } }.not_to(change { Spree::Reimbursement.count })
            end
          end

          context 'when the refund creation fails' do
            let(:interactor) { described_class.call(interactor_context) }

            let(:failure) do
              double(Interactor::Context, failure?: true, error: 'error') # rubocop:disable RSpec/VerifiedDoubles
            end

            before do
              allow(OrderManagement::RefundCredit::CreateOrganizer).to receive(:call).and_return(failure)
            end

            it 'fails with the error provided by the interactor' do
              is_expected.to be_failure

              is_expected.to have_attributes error: 'error'
            end

            it "doesn't create reimbursement and adjustment" do
              expect { call_interactor! }.not_to(change { Spree::Reimbursement.count })
            end
          end

          context 'with more info' do
            let(:order_item_summary_2) do
              create(
                :order_item_summary,
                summarable: order_item_summary.summarable,
                order_management_ref: 'line_item_2'
              )
            end
            let(:order_item_summary_4) { create(:order_item_summary, order_management_ref: 'line_item_4') }

            let(:info) do
              [
                { order_item_summary_id: 'line_item_1', amount: 2.5, label: 'valid' },
                { order_item_summary_id: 'line_item_2', amount: 2.5, label: 'valid' },
                { order_item_summary_id: 'line_item_3', amount: 2.5, label: 'missing' },
                { order_item_summary_id: 'line_item_4', amount: 2.5, label: 'related to another order' }
              ]
            end

            before do
              order_item_summary_2
              order_item_summary_4

              allow(Sentry).to receive(:capture_exception_with_message)
            end

            it 'creates only two reimbursements' do
              expect { call_interactor! }.to change { Spree::Reimbursement.count }.by(1)
            end

            it 'creates as many adjustments as many info' do
              expect { call_interactor! }.to change { Spree::Adjustment.count }.by(2)
            end

            it 'sends the errored infos to Sentry' do
              call_interactor!

              expect(Sentry).to have_received(:capture_exception_with_message).with(
                kind_of(StandardError),
                hash_including(
                  :extra,
                  message: 'OrderItemSummary not found'
                )
              )
            end
          end
        end
      end
    end
  end
end
