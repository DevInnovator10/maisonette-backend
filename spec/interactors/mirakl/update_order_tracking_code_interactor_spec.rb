# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::UpdateOrderTrackingCodeInteractor, mirakl: true do
    let(:interactor) { described_class.new(easypost_order: easypost_order) }
  let(:easypost_order) do
    instance_double Easypost::Order, spree_shipment: shipment, rate_carrier: rate_carrier, tracking_code: tracking_code
  end
  let(:shipment) { instance_double Spree::Shipment, mirakl_order: mirakl_order }
  let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: logistic_order_id }
  let(:logistic_order_id) { 'R123-A' }
  let(:rate_carrier) { 'UPS' }
  let(:tracking_code) { 'track_1234' }

  describe 'execute' do
    let(:order_tracking_payload) do
      { carrier_code: rate_carrier,
        tracking_number: tracking_code }.to_json
    end

    before do
      allow(interactor).to receive(:put)

      interactor.call
    end

    it 'sends a PUT to /tracking with tracking code and carrier' do
      expect(interactor).to have_received(:put).with("/orders/#{logistic_order_id}/tracking",
                                                     payload: order_tracking_payload)
    end
  end
end
