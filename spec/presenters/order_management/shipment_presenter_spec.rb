# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::ShipmentPresenter do
    describe '#payload' do

    subject { described_class.new(mirakl_order, status: status).payload }

    let(:status) {}
    let(:mirakl_order) do
      create(
        :mirakl_order,
        commercial_order: mirakl_commercial_order,
        shipping_tracking: tracking,
        customer_payload: customer_payload
      )
    end
    let(:mirakl_commercial_order) { create(:mirakl_commercial_order, spree_order: solidus_order) }
    let(:solidus_order) { create(:order) }
    let(:sale_order) { create(:sales_order, spree_order: solidus_order, order_summary: order_summary) }
    let(:order_summary) { create(:order_summary, order_management_ref: order_summary_id) }
    let(:order_summary_id) { 'ORDER_SUMMARY_ID' }
    let(:tracking) { 'TRACKING_NUMBER' }
    let(:customer_payload) do
      {
        'shipping_address' => {
          'firstname' => 'John',
          'lastname' => 'Doe',
          'street_1' => '1313 Broadway',
          'city' => 'New York',
          'zip_code' => '10001',
          'state' => 'New York',
          'country' => 'UNITED STATES'
        }
      }
    end

    before { sale_order }

    context 'when the status param is not present' do
      let(:expected_payload) do
        {
          attributes: { type: 'Shipment' },
          External_ID__c: mirakl_order.to_gid_param,
          OrderSummaryId: order_summary_id,
          FulfillmentOrder: { Mirakl_Order_ID__c: mirakl_order.logistic_order_id },
          TrackingNumber: tracking,
          ShipToName: 'John Doe',
          ShipToCity: 'New York',
          ShipToCountry: 'UNITED STATES',
          ShipToPostalCode: '10001',
          ShipToState: 'New York',
          ShipToStreet: '1313 Broadway'
        }
      end

      it do
        is_expected.to eq(expected_payload)
      end
    end

    context 'when the status param is present' do
      let(:status) { 'Shipped' }
      let(:expected_payload) do
        {
          attributes: { type: 'Shipment' },
          External_ID__c: mirakl_order.to_gid_param,
          OrderSummaryId: order_summary_id,
          FulfillmentOrder: { Mirakl_Order_ID__c: mirakl_order.logistic_order_id },
          TrackingNumber: tracking,
          ShipToName: 'John Doe',
          ShipToCity: 'New York',
          ShipToCountry: 'UNITED STATES',
          ShipToPostalCode: '10001',
          ShipToState: 'New York',
          ShipToStreet: '1313 Broadway',
          Status: 'Shipped'
        }
      end

      it do
        is_expected.to eq(expected_payload)
      end
    end
  end
end
