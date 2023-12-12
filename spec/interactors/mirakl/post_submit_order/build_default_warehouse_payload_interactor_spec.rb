# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::PostSubmitOrder::BuildDefaultWarehousePayloadInteractor, mirakl: true do
  describe '#call' do
    let(:interactor) { described_class.new(mirakl_order: mirakl_order) }
    let(:mirakl_order) { instance_double Mirakl::Order, logistic_order_id: 'R123-A', shipment: shipment }
    let(:shipment) { instance_double Spree::Shipment, mirakl_shop: mirakl_shop }
    let(:mirakl_shop) { instance_double Mirakl::Shop, warehouses: mirakl_warehouses }
    let(:mirakl_warehouses) { class_double Mirakl::Warehouse, blank?: warehouses_blank? }
    let(:mirakl_warehouses_ordered_by_name) { class_double Mirakl::Warehouse }
    let(:warehouses_blank?) {}
    let(:default_warehouse_payload) do
      { code: MIRAKL_DATA[:order][:additional_fields][:warehouse],
        value: 'warehouse-1' }
    end

    before do
      allow(mirakl_warehouses).to receive(:order).with(:name).and_return(mirakl_warehouses_ordered_by_name)
      allow(mirakl_warehouses_ordered_by_name).to receive(:pluck).with(:name).and_return(%w[warehouse-1 warehouse-2])
    end

    context 'when it is successful' do
      before { interactor.call }

      context 'when warehouses is empty' do
        let(:warehouses_blank?) { true }

        it 'does not add the default_warehouse_payload to mirakl_order_additional_fields_payload' do
          expect(interactor.context.mirakl_order_additional_fields_payload).to eq nil
        end
      end

      context 'when warehouses is not empty' do
        let(:warehouses_blank?) { false }

        it 'add the default_warehouse_payload to mirakl_order_additional_fields_payload' do
          expect(interactor.context.mirakl_order_additional_fields_payload).to eq [default_warehouse_payload]
        end
      end
    end

    context 'when it errors' do
      let(:exception) { StandardError.new('something went wrong') }

      before do
        allow(interactor).to receive(:rescue_and_capture)
        allow(interactor).to receive(:mirakl_warehouses).and_raise(exception)

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
