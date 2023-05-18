# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::OrderStateMachine::WaitingDebitPayment::BuildDropshipSurchargePayloadInteractor, mirakl: true do
  describe 'call' do
    let(:context) do
      described_class.call(mirakl_order: mirakl_order,
                           mirakl_order_additional_fields_payload: mirakl_order_additional_fields_payload)
    end
    let(:mirakl_order) { instance_double Mirakl::Order, shipment: shipment, logistic_order_id: 'R123-A' }
    let(:shipment) { instance_double Spree::Shipment, mirakl_shop: mirakl_shop }
    let(:mirakl_shop) { instance_double Mirakl::Shop, dropship_surcharge: dropship_surcharge }
    let(:dropship_surcharge) { nil }

    context 'when the dropship_surcharge is positive' do
      let(:dropship_surcharge) { 5.5 }
      let(:dropship_payload) do
        { code: MIRAKL_DATA[:order][:additional_fields][:dropship_surcharge],
          value: dropship_surcharge }
      end

      context 'when mirakl_order_additional_fields_payload exists' do
        let(:mirakl_order_additional_fields_payload) { [{ 'some_other' => 'hash' }] }
        let(:combined_payload) { mirakl_order_additional_fields_payload << dropship_payload }

        it 'adds the dropship surcharge to the addition fields payload' do
          expect(context.mirakl_order_additional_fields_payload).to eq combined_payload
        end
      end

      context 'when mirakl_order_additional_fields_payload is empty' do
        let(:mirakl_order_additional_fields_payload) { nil }

        it 'creates addition fields payload with dropship surcharge' do
          expect(context.mirakl_order_additional_fields_payload).to eq [dropship_payload]
        end
      end
    end

    context 'when an error is thrown' do
      let(:interactor) { described_class.new mirakl_order: mirakl_order }
      let(:exception) { StandardError.new 'some error' }

      before do
        allow(interactor).to receive_messages(rescue_and_capture: false)
        allow(interactor).to receive(:dropship_surcharge).and_raise(exception)

        interactor.call
      end

      it 'does not fail the interactor' do
        expect(interactor.context).not_to be_failure
      end

      it 'calls rescue_and_capture' do
        expect(interactor).to(
          have_received(:rescue_and_capture).with(exception,
                                                  extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        )
      end
    end
  end
end
