# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::RefundCredit::GiftCardReimbursementInteractor do
  subject(:interactor) { described_class.call(interactor_context) }

  let(:interactor_context) { {} }

  describe '#call' do
    context 'without reimbursement_method' do
      let(:interactor_context) { {} }

      it { is_expected.to be_a_success }
    end

    context 'with reimbursement_method != gift_card' do
      let(:interactor_context) { { reimbursement_method: 'not_gift_card' } }

      it { is_expected.to be_a_success }

      it "doesn't create the gift_card" do
        expect { interactor }.not_to change(Spree::GiftCard, :count)
      end
    end

    context 'when reimbursement_method == gift_card' do
      let(:interactor_context) { { reimbursement_method: 'gift_card' } }

      context 'without reimbursement' do
        it { is_expected.to be_failure }

        it 'returns the error' do
          expect(interactor.error).to eq 'Missing reimbursement'
        end
      end

      context 'with reimbursement' do
        let(:refund_notes) { 'Reimbursement note' }
        let(:refund_gift_card_email) { 'user@xample.com' }
        let(:interactor_context) do
          {
            reimbursement_method: 'gift_card',
            amount: 10.0,
            gift_card_email: refund_gift_card_email,
            notes: refund_notes,
            reason_id: 'damaged item',
            reimbursement: reimbursement,
          }
        end
        let(:order) { create(:completed_order_with_totals) }
        let(:reimbursement) { create(:reimbursement) }

        before do
          allow(Maisonette::GiftCardGeneratorOrganizer).to receive(:call).and_call_original
        end

        it { is_expected.to be_a_success }

        it 'creates a new giftcard' do
          expect { interactor }.to change(Spree::GiftCard, :count).by(1)
        end

        it 'has called Maisonette::GiftCardGeneratorOrganizer' do
          interactor

          expect(Maisonette::GiftCardGeneratorOrganizer).to have_received(:call).with(
            hash_including(
              name: "Appeasement for #{refund_notes}",
              recipient_email: refund_gift_card_email,
              gift_message: refund_notes,
              currency: 'USD',
              original_amount: interactor_context[:amount]
            )
          )
        end

        context 'when GiftCardGeneratorOrganizer fail' do
          let(:gift_card_interactor) do
            double(Interactor::Context, success?: false, error: 'error_context') # rubocop:disable RSpec/VerifiedDoubles
          end

          before { allow(Maisonette::GiftCardGeneratorOrganizer).to receive(:call).and_return(gift_card_interactor) }

          it 'returns the error' do
            expect(interactor).to be_failure

            expect(interactor.error).to eq 'Gift Card Creation failed'
            expect(interactor.extra).to eq 'error_context'
          end

          context 'when error is not present' do
            let(:gift_card_interactor) do
              double( # rubocop:disable RSpec/VerifiedDoubles
                Interactor::Context,
                success?: false,
                error: nil,
                errors: 'error_context'
              )
            end

            it 'fallback to errors' do
              expect(interactor).to be_failure

              expect(interactor.error).to eq 'Gift Card Creation failed'
              expect(interactor.extra).to eq 'error_context'
            end
          end
        end
      end
    end
  end
end
