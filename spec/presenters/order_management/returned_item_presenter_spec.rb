# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::ReturnedItemPresenter do
  describe '#payload' do
    let(:mirakl_order_line) { create :mirakl_order_line }
    let(:reason) do
      instance_double Spree::ReturnReason, name: 'Late Delivery', mirakl_code: 'INCIDENT_OPEN_LATE_DELIVERY'
    end
    let(:order_line_payload) do
      {
        'order_line_id' => mirakl_order_line.mirakl_order_line_id,
        'taxes' => taxes,
        'quantity' => 4,
        'total_price' => 10
      }
    end
    let(:mirakl_reimbursement) { build_stubbed :mirakl_order_line_reimbursement, :refund }
    let(:taxes) { [{ 'amount' => 2 }, { 'amount' => 3 }] }
    let(:order_management_entity) { instance_double OrderManagement::Reason }

    before do
      allow(reason).to receive(:order_management_entity).and_return(order_management_entity)
      allow(order_management_entity).to receive(:external_id).and_return('123')
    end

    it 'returns the return authorization payload' do
      expected_payload = {
        returnItems:
          [{
            'miraklItemId': mirakl_order_line.mirakl_order_line_id,
            'reasonExternalId': '123',
            'quantity': 4,
            'returnAmount': 10,
            'returnTaxAmount': 5,
            'mirakl_reimbursement_id': mirakl_reimbursement.id
          }]
      }

      expect(described_class.new(mirakl_order_line.mirakl_order_line_id,
                                 reason,
                                 order_line_payload,
                                 mirakl_reimbursement.id).payload).to eq(expected_payload)
    end
  end
end
