# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::ReturnAuthorizationPresenter do
  describe '#payload' do
    let(:mirakl_order_line_ids) { %w[123 456] }
    let(:reason) { instance_double Spree::ReturnReason, mirakl_code: 'Late Order Refund' }

    it 'returns the return authorization payload' do
      expected_payload = {
        data: [
          {
            "requestReasonCode": 'Late Order Refund',
            "miraklLineItemId": '123'
          },
          {
            "requestReasonCode": 'Late Order Refund',
            "miraklLineItemId": '456'
          }
        ]
      }

      expect(described_class.new(mirakl_order_line_ids, reason).payload).to eq(expected_payload)
    end
  end
end
