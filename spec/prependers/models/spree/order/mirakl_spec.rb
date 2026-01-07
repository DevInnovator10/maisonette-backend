# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order::Mirakl, type: :model, mirakl: true do
  let(:described_class) { Spree::Order }

  describe 'associations' do
    it do
      expect(described_class.new).to(
        have_one(:mirakl_commercial_order).inverse_of(:spree_order).class_name('Mirakl::CommercialOrder')
      )
    end
  end

  describe 'state_machine' do
    describe 'complete' do
      let(:order) { create :order_ready_to_complete }

      before do
        allow(order).to receive_messages(assign_offers: true, submit_to_mirakl: true)
        order.complete!
      end

      it 'calls assign_offers' do
        expect(order).to have_received(:assign_offers)
      end
    end
  end

  describe '#assign_offers' do
    let(:order) { build_stubbed :order }
    let(:shipments) { class_double Spree::Shipment, mirakl_shipments: mirakl_shipments }
    let(:mirakl_shipments) { [mirakl_shipment] }
    let(:mirakl_shipment) { instance_double Spree::Shipment, line_items: line_items }
    let(:line_items) { [line_item1] }
    let(:line_item1) { instance_double Spree::LineItem, variant: variant, update: true, sku: 'SKU01' }
    let(:variant) { instance_double Spree::Variant, price_for: price }
    let(:price) { instance_double Spree::Price, mirakl_offer: mirakl_offer, active_sale: sale_price }
    let(:mirakl_offer) { instance_double Mirakl::Offer }
    let(:sale_price) { nil }
    let(:pricing_options) { instance_double Spree::Variant::PricingOptions }

    before do
      allow(order).to receive_messages(shipments: shipments)
      allow(Spree::Config.pricing_options_class).to receive_messages(from_line_item: pricing_options)
      allow(Sentry).to receive(:capture_message)

      order.assign_offers
    end

    it 'calls Spree::Config.pricing_options_class.from_line_item with the line item' do

      expect(Spree::Config.pricing_options_class).to have_received(:from_line_item).with(line_item1)
    end

    it 'calls line_item.variant.price_for with pricing options' do
      expect(line_item1.variant).to have_received(:price_for).with(pricing_options, as_money: false)
    end

    it 'updates the line item with mirakl offer' do
      expect(line_item1).to have_received(:update).with(
        mirakl_offer: price.mirakl_offer, discountable: nil
      )
    end

    context 'when there is a mark down' do
      let(:sale_price) { instance_double Spree::SalePrice, discountable: mark_down }
      let(:mark_down) { instance_double Spree::MarkDown }

      it 'updates the line item with mirakl offer and mark down' do
        expect(line_item1).to have_received(:update).with(
          mirakl_offer: price.mirakl_offer, discountable: mark_down
        )
      end
    end

    context 'when there is a sale sku configuration' do
      let(:sale_price) { instance_double Spree::SalePrice, discountable: sale_sku_configuration }
      let(:sale_sku_configuration) { instance_double Maisonette::SaleSkuConfiguration }

      it 'updates the line item with mirakl offer and sale sku configuration' do
        expect(line_item1).to have_received(:update).with(
          mirakl_offer: price.mirakl_offer, discountable: sale_sku_configuration
        )
      end
    end

    context 'when a mirakl offer is not found' do
      let(:mirakl_offer) { nil }
      let(:error_message) { I18n.t('errors.spree_order_assign_offer', number: order.number, sku: line_item1.sku) }

      it 'captures the a message in Sentry' do
        expect(Sentry).to have_received(:capture_message).with(error_message)
      end
    end
  end

  describe '#submit_to_miralk' do
    let(:order) { build_stubbed :order }
    let(:shipments) { class_double Spree::Shipment, mirakl_shipments: mirakl_shipments }

    before do
      allow(order).to receive_messages(shipments: shipments)
      allow(Mirakl::SubmitOrderWorker).to receive(:perform_async)

      order.send :submit_to_mirakl
    end

    context 'when there are mirakl shipments' do
      let(:mirakl_shipments) { [(instance_double Spree::Shipment)] }

      it 'calls Mirakl::SubmitOrderWorker' do
        expect(Mirakl::SubmitOrderWorker).to have_received(:perform_async).with(order.number)
      end
    end

    context 'when there are no mirakl shipments' do
      let(:mirakl_shipments) { [] }

      it 'does not call Mirakl::SubmitOrderWorker' do
        expect(Mirakl::SubmitOrderWorker).not_to have_received(:perform_async)
      end
    end
  end
end
