# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Easypost::TrackerInteractor do
  describe '#call' do
    subject(:call) { interactor.call }

    let(:interactor) { described_class.new(req_tracker: payload_tracker) }
    let(:payload_tracker) do
      { 'carrier' => carrier, 'tracking_details' => tracking_details, 'tracking_code' => '123456' }
    end
    let(:carrier) { 'UPS' }
    let(:tracking_details) do
      [in_transit_tracking_detail, out_for_delivery_tracking_detail, delivered_tracking_detail].compact
    end
    let(:in_transit_tracking_detail) do
      { 'status' => 'in_transit', 'datetime' => '2019-06-03T10:09:15Z' }
    end
    let(:out_for_delivery_tracking_detail) do
      { 'status' => 'out_for_delivery', 'datetime' => '2019-06-04T10:09:12Z' }
    end
    let(:delivered_tracking_detail) do
      { 'status' => 'delivered', 'datetime' => '2019-06-05T10:09:20Z' }
    end

    let(:easypost_order) { Easypost::Order.create!(tracking_code: '123456') }
    let(:tracker) { Easypost::Tracker.create!(tracking_code: '123456') }
    let(:tracker_hash) do
      { webhook_payload: payload_tracker.to_json,
        carrier: carrier,
        easypost_order_id: easypost_order.id,
        status: 'delivered',
        date_shipped: '2019-06-03T10:09:15Z',
        date_out_for_delivery: '2019-06-04T10:09:12Z',
        date_delivered: '2019-06-05T10:09:20Z',
        fees: nil,
        est_delivery_date: nil }
    end

    before do
      easypost_order
      allow(Easypost::Tracker).to(
        receive(:find_or_initialize_by)
          .with(tracking_code: '123456')
          .and_return(tracker)
      )
      allow(tracker).to receive(:update!)

      call
    end

    context 'when there are no tracking details' do
      let(:tracking_details) { [] }

      it 'returns without failure' do
        expect(interactor.context).to be_a_success
      end
    end

    context 'when the tracker is ups' do
      it 'updates tracker with the latest status' do
        expect(tracker).to have_received(:update!).with(tracker_hash)
      end
    end

    context 'when there are fees' do
      let(:delivered_tracking_detail) do
        { 'status' => 'delivered',
          'datetime' => '2019-06-05T10:09:20Z',
          'fees' => [{ 'type' => 'LabelFee', 'amount' => 20 },
                     { 'type' => 'PostageFee', 'amount' => 50 }] }
      end

      let(:tracker_hash_with_fees) do
        tracker_hash.merge(fees: [{ 'type' => 'LabelFee', 'amount' => 20 },
                                  'type' => 'PostageFee', 'amount' => 50])
      end

      it 'updates tracker with the fees' do
        expect(tracker).to have_received(:update!).with(tracker_hash_with_fees)
      end
    end

    context 'when the there is no easypost order' do
      let(:easypost_order) {}

      let(:tracker_hash) do
        { webhook_payload: payload_tracker.to_json,
          carrier: carrier,
          easypost_order_id: nil,
          status: 'delivered',
          date_shipped: '2019-06-03T10:09:15Z',
          date_out_for_delivery: '2019-06-04T10:09:12Z',
          date_delivered: '2019-06-05T10:09:20Z',
          fees: nil,
          est_delivery_date: nil }
      end

      it 'updates tracker without the easypost order id' do
        expect(tracker).to have_received(:update!).with(tracker_hash)
      end
    end

    context 'when a status is not useful' do
      let(:tracking_details) { [available_for_pickup] }
      let(:available_for_pickup) do
        { 'status' => 'available_for_pickup', 'datetime' => '2019-06-03T10:09:15Z' }
      end
      let(:tracker_hash) do
        { webhook_payload: payload_tracker.to_json,
          carrier: carrier,
          easypost_order_id: easypost_order.id,
          status: 'available_for_pickup',
          fees: nil,
          est_delivery_date: nil }
      end

      it 'updates tracker with the status' do
        expect(tracker).to have_received(:update!).with(tracker_hash)
      end
    end
  end
end
