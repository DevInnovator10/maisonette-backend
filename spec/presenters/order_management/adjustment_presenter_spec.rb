# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::AdjustmentPresenter do
  describe '#line_item_payload' do
    it 'returns the line item adjustment payload' do
      adjustment = create(:tax_adjustment, label: 'Avalara Tax', amount: 1.0)

      expected_payload = {
        attributes: { type: 'OrderItemTaxLineItem' },
        Name: 'Avalara Tax',
        Type: 'Estimated',
        Amount: 1.0,
        TaxEffectiveDate: adjustment.created_at.iso8601,
        OrderItemId: '@{refLineItemsGroup[0].id}'
      }

      expect(described_class.new(adjustment, 0).tax_payload).to eq(expected_payload)
    end
  end

  describe '#shipment_payload' do
    it 'returns the shipment adjustment payload' do
      adjustment = create(:adjustment, label: 'Shipping Adjustment', amount: -5.0)
      expected_payload = {
        attributes: { type: 'OrderItemAdjustmentLineItem' },
        Name: 'Shipping Adjustment',
        Amount: -5.0,
        OrderItemId: '@{refLineItemsGroup[1].id}',
        OrderAdjustmentGroupId: '@{refOrderDetails[2].id}'
      }

      expect(described_class.new(adjustment, 1).line_item_payload(2)).to eq(expected_payload)
    end
  end
end
