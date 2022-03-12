# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::CreateCustomerReturnInteractor do
  describe '#call' do
    subject(:interactor_result!) { described_class.call(interactor_context) }

    context 'when no mirakl order line id is present' do
      let(:interactor_context) { {} }

      it { is_expected.to be_failure }

      it 'returns the error' do
        expect(interactor_result!.error).to eq 'Mirakl order line id required'
      end
    end

    context 'when mirakl order line id is present' do
      let(:spree_reimbursement) { create :reimbursement, mirakl_order_line_reimbursements: [mirakl_reimbursement] }
      let(:mirakl_reimbursement) do
        create :mirakl_order_line_reimbursement,
               order_line: order_line
      end
      let(:mirakl_order) { create :mirakl_order, commercial_order: mirakl_commercial_order }
      let(:mirakl_commercial_order) { create :mirakl_commercial_order, spree_order: order }
      let(:order_line) do
        create :mirakl_order_line,
               order: mirakl_order,

               line_item: order.line_items.first,
               return_authorization: return_authorization
      end
      let(:mirakl_order_line) { create :mirakl_order_line, return_authorization: return_authorization }
      let(:return_authorization) { create(:return_authorization, order_id: order.id) }
      let(:order) { create :shipped_order, line_items_count: 3, user: salesforce_user }
      let(:salesforce_user) { create(:user, :with_oms_backend_role) }
      let(:reason_code) { 'REFUND_REASON_CODE' }
      let(:refund_reason) { create :refund_reason, mirakl_code: reason_code }

      before do
        order.inventory_units.each do |unit|
          create(:return_item, return_authorization: return_authorization, inventory_unit: unit, amount: 12)
        end
        spree_reimbursement
        refund_reason
      end

      context 'with store credit refund' do
        let(:interactor_context) do
          {
            'mirakl_order_line_id': mirakl_order_line.mirakl_order_line_id,
            'mirakl_reimbursement_id': mirakl_reimbursement.id,
            'total': 30,
            'refunds': [
              {
                'reimbursement_method': 'store_credit',
                'amount': 10,
                'reason_code': reason_code
              }
            ],
            'current_user': salesforce_user
          }
        end
        let(:store_credit_category) { create(:store_credit_category, name: 'Default') }
        let(:store_credit_type) { create(:store_credit_type, name: 'Non-expiring') }

        before do
          store_credit_category
          store_credit_type
        end

        it { is_expected.to be_success }

        it 'creates the customer return' do
          expect { interactor_result! }.to change { Spree::CustomerReturn.count }.by(1)
        end
      end

      context 'with gift card refund' do
        let(:interactor_context) do
          {
            'mirakl_order_line_id': mirakl_order_line.mirakl_order_line_id,
            'mirakl_reimbursement_id': mirakl_reimbursement.id,
            'total': 30,
            'refunds': [
              {
                'reimbursement_method': 'gift_card',
                'gift_card_email': 'admin@example.com',
                'amount': 10,
                'notes': 'hey for Kanu',
                'reason_code': reason_code
              }
            ],
            'current_user': salesforce_user
          }
        end

        it { is_expected.to be_success }

        it 'creates the customer return' do
          expect { interactor_result! }.to change { Spree::CustomerReturn.count }.by(1)
        end
      end

      context 'with braintree refund' do
        let(:interactor_context) do
          {
            'mirakl_order_line_id': mirakl_order_line.mirakl_order_line_id,
            'mirakl_reimbursement_id': mirakl_reimbursement.id,
            'total': 30,
            'refunds': [
              {
                'reimbursement_method': 'braintree',
                'amount': 10,
                'payment_number': payment.number,
                'transaction_id': 1,
                'reason_code': reason_code
              }
            ],
            'current_user': salesforce_user
          }
        end
        let(:payment) { order.payments.first }
        let(:transaction) { instance_double(Braintree::Transaction, id: 1, order_id: order.id) }

        it { is_expected.to be_success }

        it 'creates the customer return' do
          expect { interactor_result! }.to change { Spree::CustomerReturn.count }.by(1)
        end
      end
    end
  end
end
