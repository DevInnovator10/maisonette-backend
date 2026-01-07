# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::CreateRefundsInteractor do
  describe '#call' do
    subject(:interactor) { described_class.call(context) }

    let(:context) do
      { refunds: refunds, current_user: current_user, order: order, total: total }
    end

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
    let(:current_user) { create(:user) }
    let(:reason_code) { 'REFUND_REASON_1' }
    let(:order) { create(:order) }
    let(:total) { 10 }
    let(:refund_reason) { create :refund_reason, mirakl_code: reason_code }

    before { refund_reason }

    context 'without refunds' do
      let(:refunds) {}

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq 'Missing refunds'
      end

    end

    context 'without current user' do
      let(:current_user) {}

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq 'Missing current user'
      end
    end

    context 'without order' do
      let(:order) {}

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq 'Missing order'
      end
    end

    context 'without total' do
      let(:total) {}

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq 'Missing reimbursement and total'
      end
    end

    context 'when refunds array is empty' do
      let(:refunds) { [] }

      it 'fails' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq 'No Refund/Credit created'
      end
    end

    context 'when the refund creation raises an error' do
      before do
        allow(OrderManagement::RefundCredit::CreateOrganizer).to receive(:call).and_raise(StandardError)
      end

      it { expect { interactor }.to raise_error(StandardError) }

      it "doesn't create reimbursement and adjustment" do
        expect { -> { interactor } }.not_to(change { Spree::Reimbursement.count })
      end
    end

    context 'when the refund creation fails' do
      let(:failure) do
        double(Interactor::Context, failure?: true, error: 'error') # rubocop:disable RSpec/VerifiedDoubles
      end

      before do
        allow(OrderManagement::RefundCredit::CreateOrganizer).to receive(:call).and_return(failure)
      end

      it 'fails with the error provided by the interactor' do
        expect(interactor).to be_a_failure
        expect(interactor.error).to eq 'error'
      end

      it "doesn't create reimbursement and adjustment" do
        expect { interactor }.not_to(change { Spree::Reimbursement.count })
      end
    end

    context 'when successful' do
      context 'when passing the total' do
        it 'creates the reimbursement' do
          expect { interactor }.to change { Spree::Reimbursement.count }.by(1)

          expect(interactor.reimbursement).to have_attributes(
            reimbursement_status: 'reimbursed',
            total: total
          )
        end
      end

      context 'when passing the reimbursement' do
        let(:context) do
          { refunds: refunds, current_user: current_user, order: order, reimbursement: reimbursement }
        end
        let(:reimbursement) { create(:reimbursement) }

        before do
          reimbursement
        end

        it "doesn't create a new reimbursement" do
          expect { interactor }.not_to(change { Spree::Reimbursement.count })

          expect(interactor.reimbursement).to eq(reimbursement)
        end
      end

      context 'with refunds for giftcard' do
        it { expect(interactor).to be_success }
      end

      context 'with refunds for store credit' do
        let(:refunds) { [{ reimbursement_method: 'store_credit', amount: 10.0, reason_code: reason_code }] }

        before do
          reimbursement_interactor = OrderManagement::RefundCredit::StoreCreditReimbursementInteractor
          create(:store_credit_category, name: reimbursement_interactor::STORE_CREDIT_CATEGORY_NAME)
          create(:store_credit_type, name: reimbursement_interactor::STORE_CREDIT_TYPE_NAME)
        end

        it { expect(interactor).to be_success }
      end

      context 'with refunds for braintree' do
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
        let(:payment) { create(:payment, amount: 15, order: order) }

        it { expect(interactor).to be_success }
      end

      context 'with refunds for afterpay' do
        let(:refunds) do
          [
            {
              reimbursement_method: 'afterpay',
              amount: 10.0,
              payment_number: payment.number,
              transaction_id: 'ABC123',
              reason_code: reason_code
            }
          ]
        end
        let(:payment) { create(:payment, amount: 15, order: order) }

        it { expect(interactor).to be_success }
      end
    end
  end
end
