# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderManagement::ShippingLineItemPresenter do
  describe '#payload' do
    let(:sales_order) { create(:sales_order, spree_order: shipment.order) }
    let(:shipment) { create(:shipment, cost: 19.95) }

    context 'when payload is complete' do
      let!(:expected_payload) do
        {
          attributes: { type: 'OrderItem' },
          Description: 'Shipping',
          Type: 'Delivery Charge',
          Quantity: 1,
          TotalLineAmount: 19.95,
          UnitPrice: 19.95,
          Product2Id: '01t1b000002KSJNAA4',
          PricebookEntryId: '01u1b000005oYUgAAM',
          OrderDeliveryGroupId: '@{refDeliveryGroups[0].id}',
          OrderId: '@{refOrder.id}',
          Shipping__c: true,
          External_ID__c: order_item.external_id,
          avalara_merchant_seller_identifier__c: '2001'
        }
      end
      let(:order_item) do
        create(:order_item_summary, summarable_type: 'Spree::Shipment',
                                    summarable_id: shipment.id,
                                    sales_order_id: sales_order.id)
      end

      before { create(:vendor, name: 'Maisonette', avalara_code: '2001') }

      it 'returns shipment order item payload' do
        delivery_group_ref = 'refDeliveryGroups[0]'

        expect(described_class.new(shipment, delivery_group_ref).payload).to eq(expected_payload)
      end

      context 'when shipment promotions' do
        let(:promo_category) { create(:promotion_category, code: 'shipping_promotion') }
        let(:promo) { create(:promotion, :with_line_item_adjustment, promotion_category: promo_category) }

        before do
          create(:adjustment, adjustable: shipment, amount: -9.95, eligible: true, source: promo.actions[0])
          create(:adjustment, adjustable: shipment, amount: -9.95, eligible: false, source: promo.actions[0])
          create(:adjustment, adjustable: shipment, amount: -5.00, eligible: true)
        end

        it 'returns shipment cost with eligible shipping promotions amount' do
          expect(described_class.new(shipment, '').payload).to include(
            TotalLineAmount: 10.0,
            UnitPrice: 10.0
          )
        end
      end
    end

    context 'when order item summary is not found' do
      before { create(:sales_order, spree_order: shipment.order) }

      it 'raises an exception' do
        delivery_group_ref = 'refDeliveryGroups[0]'

        expect { described_class.new(shipment, delivery_group_ref).payload }.to raise_error(
          ActiveRecord::RecordNotFound
        )
      end
    end
  end
end
