# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::CreateCartonInteractor do
    describe '#call' do
    subject(:interactor_result) { described_class.call(interactor_context) }

    context 'without external_id' do
      let(:interactor_context) { {} }

      it do
        expect { interactor_result }.to(
          raise_error(
            ApplicationInteractor::MissingParams,
            'Missing required parameters: items and external_id'
          )
        )
      end
    end

    context 'with valid params' do
      let(:shipment) do
        line_item.inventory_units.first.shipment.tap do |shipment|
          shipment.update(shipping_rates: [create(:shipping_rate, selected: true)])
        end
      end
      let(:order_item_summary) do
        create(:order_item_summary, order_management_ref: 'line_item_1', summarable: line_item)
      end
      let(:line_item) do
        create(:line_item).tap do |line_item|
          inventory_unit = create(:inventory_unit, line_item: line_item)
          create(:inventory_unit, line_item: line_item, shipment: inventory_unit.shipment)
        end
      end
      let(:item_1) { { order_item_summary_ref: order_item_summary.order_management_ref, quantity: 1 } }
      let(:items) { [item_1] }
      let(:external_id) { mirakl_order.to_gid_param }
      let(:mirakl_order) { create(:mirakl_order, shipment: shipment) }
      let(:interactor_context) do
        {
          external_id: external_id,
          tracking: 'tracking_code',
          shipping_carrier_code: 'CARRIER_CODE',
          items: items
        }
      end

      it { is_expected.to be_success }

      it 'creates a new carton with tracking info' do
        expect { interactor_result }.to change(Spree::Carton, :count).from(0).to(1)

        created_carton = Spree::Carton.last
        expect(created_carton).to have_attributes(
          external_number: shipment.number,
          tracking: interactor_context[:tracking],
          shipping_carrier_code: interactor_context[:shipping_carrier_code]
        )
      end

      it 'updates the shipment tracking code' do
        expect { interactor_result }.to change { shipment.reload.tracking }.to(interactor_context[:tracking])
      end

      context 'when shipment is not found' do
        let(:external_id) { 'not_existing_external_id' }

        it { is_expected.to be_failure }

        it 'returns the error' do
          expect(interactor_result.error).to eq 'Missing shipment'
        end
      end

      context 'when items is empty' do
        let(:items) { [] }

        it 'fails the carton creation' do
          expect do
            interactor_result
          end.to raise_error(
            an_instance_of(ActiveRecord::RecordInvalid)
              .and(having_attributes(record: kind_of(Spree::Carton)))
          )
        end
      end

      context 'when the item summaries is not related to line item' do
        let(:shipment) { line_item.shipments.first }
        let(:order_item_summary) do
          create(:order_item_summary, order_management_ref: 'line_item_1', summarable: shipment)
        end

        before { allow(Sentry).to receive(:capture_exception_with_message) }

        it 'fails the carton creation' do
          expect(interactor_result).to be_failure

          expect(interactor_result).to have_attributes(error: 'Spree::LineItem for line_item_1 not found')
          expect(Sentry).to have_received(:capture_exception_with_message).with(
            an_instance_of(ActiveRecord::RecordNotFound),
            message: 'Spree::LineItem for line_item_1 not found'
          )
        end
      end

      context 'when there are two item summaries' do
        let(:items) { [item_1, item_2] }
        let(:item_2) { { order_item_summary_ref: order_item_summary_2.order_management_ref, quantity: 1 } }

        let(:order_item_summary_2) do
          create(:order_item_summary, order_management_ref: 'line_item_2', summarable: line_item_2)
        end
        let(:line_item_2) do
          create(:line_item).tap do |line_item|
            inventory_unit = create(:inventory_unit, line_item: line_item)
            create(:inventory_unit, line_item: line_item, shipment: inventory_unit.shipment)
          end
        end

        it 'creates the carton with two inventory_units' do
          expect { interactor_result }.to change(Spree::Carton, :count).from(0).to(1)

          created_carton = Spree::Carton.last
          expect(created_carton.inventory_units.count).to eq 2
        end

        context 'when quantity for item summary is 2' do
          let(:item_1) { { order_item_summary_ref: order_item_summary.order_management_ref, quantity: '2' } }

          it 'creates the carton with two inventory_units' do
            expect { interactor_result }.to change(Spree::Carton, :count).from(0).to(1)

            created_carton = Spree::Carton.last
            expect(created_carton.inventory_units.count).to eq 3
          end
        end
      end
    end
  end
end
