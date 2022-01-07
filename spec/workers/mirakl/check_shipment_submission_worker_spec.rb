# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::CheckShipmentSubmissionWorker, mirakl: true do
  describe '#perform' do
    let(:mirakl_shipment_no_mirakl_order_1) { create(:shipment, order: order_completed_yesterday, number: 'H001') }
    let(:mirakl_shipment_no_mirakl_order_2) { create(:shipment, order: order_completed_yesterday, number: 'H002') }
    let(:mirakl_shipment_no_mirakl_order_completed_today) { create(:shipment, order: order_completed_today) }
    let(:mirakl_shipment_with_mirakl_order) { create(:shipment, order: order_completed_yesterday) }
    let(:non_mirakl_shipment) { create :shipment, order: order_completed_yesterday }
    let(:mirakl_order) { create :mirakl_order, shipment: mirakl_shipment_with_mirakl_order }
    let(:order_completed_yesterday) { create :order, completed_at: Time.current.yesterday, state: :complete }
    let(:order_completed_today) { create :order, completed_at: Time.current, state: :complete }
    let(:free_shipping_method) { create :shipping_method, admin_name: 'Free Shipping (Gift Cards)' }
    let(:error_message) do
      'Orders and Shipments with missing Mirakl Orders: ' \
      "{\"#{order_completed_yesterday.number}\"=>" \
      "[\"#{mirakl_shipment_no_mirakl_order_1.number}\"," \
      " \"#{mirakl_shipment_no_mirakl_order_2.number}\"]}"
    end

    context 'when there are shipments with missing mirakl orders' do
      before do
        mirakl_shipment_no_mirakl_order_1
        mirakl_shipment_no_mirakl_order_2
        mirakl_shipment_with_mirakl_order && mirakl_order
        mirakl_shipment_no_mirakl_order_completed_today
        non_mirakl_shipment.selected_shipping_rate.update(shipping_method: free_shipping_method)

        allow(Sentry).to receive(:capture_message)

        described_class.new.perform
      end

      it 'captures the shipments missing mirakl orders via Sentry' do
        expect(Sentry).to have_received(:capture_message).with(error_message, tags: { notify: :order_sync_issues })
      end
    end

    context 'when there are no shipments missing mirakl orders' do
      before do
        allow(Sentry).to receive(:capture_message)

        described_class.new.perform
      end

      it 'does not capture an error message' do
        expect(Sentry).not_to have_received(:capture_message)
      end
    end
  end
end
