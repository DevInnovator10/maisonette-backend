# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::Easypost::CreateOrder::InitializeEasypostOrderInteractor, mirakl: true do
  describe 'call' do
    let(:interactor) { described_class.new mirakl_order: mirakl_order, boxes: boxes }
    let(:boxes) { [box1, box2] }
    let(:box1) { { width: 5.6, length: 6.4, height: 2.5, weight: 3 } }
    let(:box2) { { width: 6.5, length: 4.6, height: 5.2, weight: 2 } }
    let(:mirakl_order) { instance_double Mirakl::Order, shipment: shipment, logistic_order_id: 'R123-A' }
    let(:shipment) { instance_double Spree::Shipment, easypost_orders: easypost_order_class, mirakl_shop: mirakl_shop }
    let(:mirakl_shop) { instance_double Mirakl::Shop, manage_own_shipping?: manage_own_shipping? }
    let(:easypost_order_class) { class_double Easypost::Order, new: easypost_order }
    let(:easypost_order) do
      instance_double Easypost::Order,
                      easypost_parcels: easypost_parcel_class,
                      easypost_api_key: 'api12345',
                      fetch_api_key: true,
                      fetch_and_send_easypost_error: true
    end
    let(:easypost_parcel_class) { class_double Easypost::Parcel, new: easypost_parcel }
    let(:easypost_parcel) { instance_double Easypost::Parcel, create_easypost_parcel: true }

    context 'when it is successful' do
      before do
        interactor.call
      end

      context 'when the shop manages their own shipping' do
        let(:manage_own_shipping?) { true }

        it 'does not assign context.easypost_order with an Easypost::Order' do
          expect(interactor.context.easypost_order).to eq nil
        end
      end

      context 'when the shop does not manage their own shipping' do
        let(:manage_own_shipping?) { false }

        it 'assigns context.easypost_order with an Easypost::Order' do
          expect(interactor.context.easypost_order).to eq easypost_order
        end

        it 'initialises an easypost order on the mirakl shipment' do
          expect(mirakl_order.shipment).to have_received(:easypost_orders)
          expect(easypost_order_class).to have_received(:new)
        end

        it 'initialises easypost parcels on the easypost parcel per box' do
          expect(easypost_order).to have_received(:easypost_parcels).twice
          boxes.each do |box|
            expect(easypost_parcel_class).to have_received(:new).with(length: box[:length], width: box[:width],
                                                                      height: box[:height], weight: box[:weight])
          end
        end

        it 'calls create_easypost_parcel on the parcels' do
          expect(easypost_parcel).to(have_received(:create_easypost_parcel)
                                       .with(easypost_api_key: easypost_order.easypost_api_key)
                                       .twice)
        end

        it 'calls fetch_api_key on Easypost::Order' do
          expect(easypost_order).to have_received(:fetch_api_key)
        end
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new('something went wrong') }
      let(:manage_own_shipping?) { false }

      before do
        allow(interactor).to receive(:rescue_and_capture)
        allow(interactor).to receive(:create_parcel).and_raise(exception)

        interactor.call
      end

      it 'rescues and captures the exception' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        )
      end

      it 'adds error_message to context' do
        expect(interactor.context.error_message).to eq exception.message
      end

      context 'when the exception is an EasyPost::Error' do
        let(:exception) { EasyPost::Error.new('something went wrong') }

        it 'calls easypost_order.fetch_and_send_easypost_error' do
          expect(easypost_order).to have_received(:fetch_and_send_easypost_error)
        end

        it 'adds easypost_exception to context' do
          expect(interactor.context.easypost_exception).to eq exception
        end
      end
    end
  end
end
