# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cartonization::PrepareCartonizationInteractor do
  include_context 'when cartonizing an order with line items'

  let(:context) { described_class.call mirakl_shop: mirakl_shop, mirakl_order: mirakl_order }
  let(:box_sizes) { %w[mailer-10-8-3 mailer-16-10-8 box-16-16-10-40 box-24-16-10] }

  let(:li_ships_alone) do
    instance_double Spree::LineItem,
                    offer_settings: offer_settings_ships_alone, internal_package_dimensions: li1_dimensions
  end
  let(:offer_settings_ships_alone) { instance_double Spree::OfferSettings, ships_alone: true, vendor_sku: sku1, id: 1 }
  let(:sku1) { 'sku1' }

  let(:li_mailer) do
    instance_double Spree::LineItem,
                    offer_settings: offer_settings_for_mailer, internal_package_dimensions: li1_dimensions
  end
  let(:offer_settings_for_mailer) do
    instance_double Spree::OfferSettings, ships_alone: false, ships_in_mailer: true, vendor_sku: sku2, id: 2
  end
  let(:sku2) { 'sku2' }

  let(:li_no_mailer) do
    instance_double Spree::LineItem,
                    offer_settings: offer_settings_no_mailer, internal_package_dimensions: li1_dimensions
  end
  let(:offer_settings_no_mailer) do
    instance_double Spree::OfferSettings, ships_alone: false, ships_in_mailer: false, vendor_sku: sku3, id: 3
  end
  let(:sku3) { 'sku3' }

  before do
    allow(Maisonette::Config).to receive(:fetch).with('paccurate.api_key').and_return(true)
    allow(Rails.logger).to receive(:info).and_call_original
  end

  context 'when there are no available box types' do
    let(:box_sizes) { [] }
    let(:error_details) { { message: 'Missing cartonization box sizes', vendor: mirakl_shop.name } }

    it 'is a failure' do
      expect(context).to be_a_failure
      expect(context.message).to eq error_details
    end

    it 'logs the failure' do
      context
      expect(Rails.logger).to have_received(:info).with(error_details)
    end
  end

  context 'when there are line items without cartonization dimensions' do
    let(:shipment_line_items) { [li_ships_alone, li_no_mailer] }
    let(:li1_dimensions) { {} }
    let(:extras) { { mirakl_shop_id: mirakl_shop.shop_id, mirakl_order_id: mirakl_order.logistic_order_id } }
    let(:error_details) do
      {
        message: 'Missing cartonization dimensions',
        vendor: mirakl_shop.name,
        vendor_skus: shipment_line_items.map(&:offer_settings).map(&:vendor_sku)
      }
    end

    it 'is a failure' do
      expect(context).to be_a_failure
      expect(context.message).to eq error_details
    end

    it 'sends the correct message to be logged' do
      context
      expect(Rails.logger).to have_received(:info).with(error_details)
    end
  end

  context 'when there are box sizes' do
    let(:box_sizes) { %w[mailer-10-8-3 mailer-16-10-8 box-16-16-10-40 box-24-16-10] }

    it 'returns mailers in available_mailers' do
      expect(context.available_mailers).to contain_exactly('mailer-10-8-3', 'mailer-16-10-8')
    end

    it 'returns all other types in available_box_types' do
      expect(context.available_box_sizes).to contain_exactly('box-24-16-10', 'box-16-16-10-40')
    end
  end

  context 'when there are line items that ship alone' do
    let(:shipment_line_items) { Array.wrap(li_ships_alone) }

    it 'sets the ships alone line items' do
      expect(context.ships_alone_line_items).to contain_exactly(li_ships_alone)
    end

    context 'when there are also line items that do not ship alone' do
      let(:shipment_line_items) { [li_ships_alone, li_mailer] }

      it 'sets the ships alone line items' do
        expect(context.ships_alone_line_items).to contain_exactly(li_ships_alone)
      end

      it 'sets the remaining line items as cartonized line items' do
        expect(context.cartonized_line_items).to contain_exactly(li_mailer)
      end
    end
  end

  context 'when determining mailer eligibility' do
    let(:line_items) { Array.wrap(li_mailer) }

    context 'when there are no available mailers' do
      let(:box_sizes) { %w[box-10-10-10] }

      it 'sets ships_in_mailer to false' do
        expect(context.ships_in_mailer).to be false
      end
    end

    context 'when there are available mailers' do
      let(:box_sizes) { %w[mailer-10-10-10 box-20-10-10] }

      context 'when there are line items that do not ship in a mailer' do
        let(:shipment_line_items) { [li_mailer, li_no_mailer] }

        it 'sets ships in mailer to false' do
          expect(context.ships_in_mailer).to be false
        end
      end

      context 'when cartonized_line_items is empty' do
        let(:line_items) { Array.wrap(li_ships_alone) }

        it 'sets ships_in_mailer to false' do
          expect(context.ships_in_mailer).to be false
        end
      end

      context 'when all line items can ship in a mailer' do
        let(:shipment_line_items) { Array.wrap(li_mailer) }

        it 'sets ships in mailer to true' do
          expect(context.ships_in_mailer).to be true
        end
      end
    end
  end
end
