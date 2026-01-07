# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::BuildOrderFeePayloadInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'R123-A' }
    let(:order_fee_payload) do
      [{ code: MIRAKL_DATA[:order][:additional_fields][:order_fee],
         value: order_fee }]
    end
    let(:order_fee) {}

    context 'when it is successful' do
      before do
        allow(interactor).to receive(:calculate_order_fee) { interactor.context.order_fee = order_fee }
        interactor.call
      end

      context 'when there is no order_fee' do
        let(:order_fee) {}

        it 'does not add the order_fee to the mirakl_order_additional_fields_payload' do
          expect(interactor.context.mirakl_order_additional_fields_payload).to eq nil
        end
      end

      context 'when there is an order_fee' do
        let(:order_fee) { 5.25 }

        it 'adds the order_fee to the mirakl_order_additional_fields_payload' do
          expect(interactor.context.mirakl_order_additional_fields_payload).to eq order_fee_payload
        end
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new('something went wrong') }

      before do
        allow(interactor).to receive(:rescue_and_capture)
        allow(interactor).to receive(:calculate_order_fee).and_raise(exception)

        interactor.call
      end

      it 'rescues and captures the exception' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        )
      end
    end
  end

  describe '#calculate_order_fee' do
    subject(:calculate_order_fee) { described_class.new(mirakl_order: mirakl_order).send(:calculate_order_fee) }

    let(:mirakl_order) { instance_double Mirakl::Order, state: state, order_fee: order_fee, shipment: shipment }
    let(:shipment) { instance_double Spree::Shipment, mirakl_shop: mirakl_shop, shipping_method: shipping_method }
    let(:mirakl_shop) do
      instance_double Mirakl::Shop, order_fee_freight: order_fee_freight, order_fee_parcel: order_fee_parcel
    end

    let(:order_fee) {}
    let(:shipping_method) {}
    let(:order_fee_freight) { 25.50 }
    let(:order_fee_parcel) { 5.25 }

    context 'when the order is CANCELED or REFUSED' do
      let(:state) { 'REFUSED' }

      context 'when the mirakl order has order_fee' do
        let(:order_fee) { 5.25 }

        it 'returns 0.0' do
          expect(calculate_order_fee).to eq 0.0
        end
      end

      context 'when the mirakl order does not have order_fee' do
        let(:order_fee) {}

        it 'returns nil' do
          expect(calculate_order_fee).to eq nil
        end
      end
    end

    context 'when the order is WAITING_ACCEPTANCE' do
      let(:state) { 'WAITING_ACCEPTANCE' }

      context 'when the shipping method is freight' do
        let(:shipping_method) { instance_double Spree::ShippingMethod, name: 'Freight' }

        it 'returns the freight order fee' do
          expect(calculate_order_fee).to eq order_fee_freight
        end
      end

      context 'when the shipping method is parcel' do
        let(:shipping_method) { instance_double Spree::ShippingMethod, name: 'Parcel' }

        it 'returns the parcel order fee' do
          expect(calculate_order_fee).to eq order_fee_parcel
        end
      end
    end
  end
end
