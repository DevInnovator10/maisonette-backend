# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::UpdateOrderReturnTrackingInteractor, mirakl: true do
  let(:update_order_returns_tracking) do
    described_class.new(logistic_order_id: logistic_order_id,
                        tracking_code: tracking_code,
                        tracking_url: easypost_url)
  end
  let(:logistic_order_id) { 'order_id_123' }
  let(:tracking_code) { 'track_code_123' }
  let(:easypost_url) { 'www.easypost.com/tracking?track_code_123' }

  describe '#call' do
    let(:order_multiple_parcels_payload) do
      { order_additional_fields:
          [{ code: MIRAKL_DATA[:order][:additional_fields][:returns_tracking_code],
             value: tracking_code },
           { code: MIRAKL_DATA[:order][:additional_fields][:returns_easypost_tracking_url],
             value: easypost_url }] }.to_json
    end

    before do
      allow(update_order_returns_tracking).to receive(:put)

      update_order_returns_tracking.call
    end

    it 'sends a valid attach document payload' do
      expect(update_order_returns_tracking).to(
        have_received(:put).with("/orders/#{logistic_order_id}/additional_fields",
                                 payload: order_multiple_parcels_payload)
      )
    end
  end
end
