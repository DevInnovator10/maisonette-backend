# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::PostSubmitOrder::BuildShipByDatePayloadInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) do
      described_class.new(mirakl_order: mirakl_order)
    end
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'R123-A', ship_by: ship_by }

    let(:ship_by) { '2019-05-22 10:45' }

    let(:send_ship_by_payload) do
      [{ code: MIRAKL_DATA[:order][:additional_fields][:fulfil_by_date],
         value: '2019-05-22T10:45:00-04:00' },
       { code: MIRAKL_DATA[:order][:additional_fields][:fulfil_by_time],
         value: '1045' }]
    end

    context 'when it is successful' do

      before { interactor.call }

      it 'add the ship_by_payload to mirakl_order_additional_fields_payload' do
        expect(interactor.context.mirakl_order_additional_fields_payload).to eq send_ship_by_payload
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new('something went wrong') }

      before do
        allow(interactor).to receive(:rescue_and_capture)
        allow(interactor).to receive(:ship_by).and_raise(exception)

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
end
