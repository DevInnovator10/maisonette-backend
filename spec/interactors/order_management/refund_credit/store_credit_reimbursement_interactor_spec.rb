# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::RefundCredit::StoreCreditReimbursementInteractor do
  subject(:interactor) { described_class.call(interactor_context) }

  let(:interactor_context) { {} }
  let(:salesforce_user) { create(:user, :with_oms_role) }

  before do
    create(:store_credit_category, name: described_class::STORE_CREDIT_CATEGORY_NAME)
    create(:store_credit_type, name: described_class::STORE_CREDIT_TYPE_NAME)
  end

  describe '#call' do
    context 'without reimbursement_method' do
      let(:interactor_context) { {} }

      it { is_expected.to be_a_success }
    end

    context 'with reimbursement_method != store_credit' do
      let(:interactor_context) { { reimbursement_method: 'not_store_credit' } }

      it { is_expected.to be_a_success }

      it "doesn't create the store_credit and reimbursement credit" do
        expect { interactor }.not_to change(Spree::Reimbursement::Credit, :count)
        expect { interactor }.not_to change(Spree::StoreCredit, :count)
      end
    end

    context 'when reimbursement_method == store_credit' do
      let(:interactor_context) { { reimbursement_method: 'store_credit' } }

      context 'without reimbursement' do
        it { is_expected.to be_failure }

        it 'returns the error' do
          expect(interactor.error).to eq 'Missing reimbursement'
        end
      end

      context 'with reimbursement' do
        let(:refund_notes) { 'Reimbursement note' }
        let(:interactor_context) do
          {
            reimbursement_method: 'store_credit',
            amount: 10.00,
            reimbursement: reimbursement,
            notes: refund_notes,
            current_user: salesforce_user
          }
        end
        let(:reimbursement) { create(:reimbursement) }

        it { is_expected.to be_a_success }

        context 'when the user is guest' do
          before { reimbursement.order.update(user: nil, email: 'admin@example.com') }

          it { is_expected.to be_failure }

          it 'returns the error' do
            expect(interactor.error).to eq "Can't create a store credit reimbursement for order without user"
          end
        end

        it 'creates a new store credit' do
          expect { interactor }.to change(Spree::StoreCredit, :count).by(1)

          expect(interactor.store_credit).to have_attributes(
            amount: 10.00,
            user: reimbursement.order.user,
            memo: interactor[:notes]
          )
        end

        it 'creates a new reimbursement credit' do
          expect { interactor }.to change(Spree::Reimbursement::Credit, :count).by(1)

          expect(interactor.credit).to have_attributes(
            amount: 10.00,
            reimbursement: reimbursement
          )
        end
      end
    end
  end
end
