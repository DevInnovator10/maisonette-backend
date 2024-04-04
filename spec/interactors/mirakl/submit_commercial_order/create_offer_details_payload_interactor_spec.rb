# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::SubmitCommercialOrder::CreateOfferDetailsPayloadInteractor, mirakl: true do
  describe '#call' do
    let(:offers_array) do
      [offer_1, offer_2]
    end
    let(:offer_1) do
      { 'currency_iso_code': 'USD',
        'offer_id': 2009,
        'offer_price': 10.0,
        'price': 20.0,
        'quantity': 2,
        'shipping_price': shipping_price,
        'shipping_type_code': shipping_method.mirakl_shipping_method_code,
        'taxes': taxes,
        'order_line_additional_fields': boxes + total_order_line_cost_price,
        'shipping_deadline': ship_by_date.iso8601 }
    end
    let(:offer_2) do
      { 'currency_iso_code': 'USD',
        'offer_id': 2010,
        'offer_price': 10.0,
        'price': 20.0,
        'quantity': 2,
        'shipping_price': shipping_price,
        'shipping_type_code': shipping_method.mirakl_shipping_method_code,
        'taxes': taxes,
        'order_line_additional_fields': boxes + total_order_line_cost_price,
        'shipping_deadline': ship_by_date.iso8601 }
    end
    let(:total_order_line_cost_price) { [] }
    let(:taxes) { nil }
    let(:boxes) { [] }
    let(:shipping_price) { 0.0 }
    let(:shipping_promo_total) { 0.0 }

    let(:mirakl_commercial_order) { instance_double Mirakl::CommercialOrder, spree_order: spree_order, id: 5 }
    let(:spree_order) { instance_double Spree::Order, currency: 'USD', shipments: shipments, payments: [payment] }
    let(:shipments) { class_double Spree::Shipment, ready: ready_shipments }
    let(:ready_shipments) { class_double Spree::Shipment, mirakl_shipments: mirakl_shipments }
    let(:mirakl_shipments) { [shipment] }
    let(:shipment) do
      instance_double Spree::Shipment,
                      state: 'ready',
                      tracking: 'TrackNumber',
                      shipping_method: shipping_method,
                      cost: shipping_price,
                      promo_total: shipping_promo_total,
                      line_items: line_items,
                      inventory_units: inventory_units,
                      stock_location: stock_location
    end
    let(:stock_location) { instance_double Spree::StockLocation, mirakl_shop: mirakl_shop }
    let(:shipping_method) { instance_double Spree::ShippingMethod, mirakl_shipping_method_code: 'ground' }
    let(:mirakl_shop) do
      instance_double Mirakl::Shop,
                      cost_price?: cost_price_vendor,
                      send_shipping_cost: send_shipping_cost,
                      vendor: vendor,
                      cartonize_shipments: cartonize_shipments
    end
    let(:cartonize_shipments) { false }
    let(:vendor) { instance_double Spree::Vendor }
    let(:send_shipping_cost) { true }
    let(:cost_price_vendor) { false }
    let(:payment) { instance_double(Spree::Payment, source_type: '') }

    let(:order) { instance_double Spree::Order, number: 'foo' }

    let(:line_items) { [line_item1, line_item2] }
    let(:line_item1) do
      instance_double Spree::LineItem,
                      price: 10.0,
                      amount: 20.0,
                      quantity: 2,
                      variant: variant,
                      product: product,
                      mirakl_offer_id: mirakl_offer.offer_id,
                      adjustments: adjustments,
                      discountable: discountable,
                      monogram: monogram,
                      offer_settings: offer_settings1,
                      internal_package_dimensions: internal_package_dimensions,
                      order: order
    end
    let(:line_item2) do
      instance_double Spree::LineItem,
                      price: 10.0,
                      amount: 20.0,
                      quantity: 2,
                      variant: variant_2,
                      product: product_2,
                      mirakl_offer_id: mirakl_offer_2.offer_id,
                      adjustments: adjustments,
                      discountable: nil,
                      monogram: nil,
                      offer_settings: offer_settings2,
                      internal_package_dimensions: {
                        'internal_package1' => {
                          'height' => '7.0', 'length' => '5.0', 'width' => '3.0', 'weight' => '2'
                        }
                      },
                      order: order
    end
    let(:internal_package_dimensions) do
      { 'internal_package1' => { 'height' => '10.0', 'length' => '12.0', 'width' => '8.0', 'weight' => '7.9' } }
    end
    let(:offer_settings1) do
      instance_double Spree::OfferSettings,
                      id: 1,
                      variant: variant,
                      vendor: vendor,
                      vendor_sku: 'vendor_sku1'
    end

    let(:offer_settings2) do
      instance_double Spree::OfferSettings,
                      id: 2,
                      variant: variant_2,
                      vendor: vendor,
                      vendor_sku: 'vendor_sku2'
    end

    let(:inventory_units) { [inventory_unit_1, inventory_unit_2] }
    let(:inventory_unit_1) { instance_double Spree::InventoryUnit, line_item: line_item1 }
    let(:inventory_unit_2) { instance_double Spree::InventoryUnit, line_item: line_item2 }

    let(:variant) { build_stubbed :variant }
    let(:product) { instance_double Spree::Product, box_properties: [], property: nil }
    let(:variant_2) { build_stubbed :variant }
    let(:product_2) { instance_double Spree::Product, box_properties: [], property: nil }
    let(:mirakl_offer) { instance_double Mirakl::Offer, offer_id: 2009 }
    let(:mirakl_offer_2) { instance_double Mirakl::Offer, offer_id: 2010 }
    let(:adjustments) { class_double Spree::Adjustment, find_by: nil }
    let(:discountable) {}
    let(:monogram) {}
    # rubocop:disable RSpec/VerifiedDoubles
    let(:ship_by_context) do
      double Mirakl::PostSubmitOrder::CalculateLeadTimeToShipInteractor, success?: true, ship_by: ship_by_date
    end
    # rubocop:enable RSpec/VerifiedDoubles
    let(:ship_by_date) { Time.current }

    let(:interactor) { described_class.new(commercial_order: mirakl_commercial_order, resubmit: false) }
    let(:context) do
      interactor.call
      interactor.context
    end

    before do
      allow(Mirakl::PostSubmitOrder::CalculateLeadTimeToShipInteractor).to receive(:call).and_return(ship_by_context)
      allow(interactor).to receive(:legacy_box_data).and_call_original
      allow(interactor).to receive(:cartonization_dimensions_for).and_call_original
      allow(Sentry).to receive(:capture_message)
    end

    context 'when there are 2 line items in the order' do
      it 'creates the payload from spree order as in the fixture' do
        expect(context.offers_details_payload).to eq offers_array
      end

      context 'when taxes are applied to the order' do
        let(:taxes) { { taxes: [{ amount: '1.0', code: 'TAXDEFAULT' }] } }
        let(:tax_adjustment) { instance_double(Spree::Adjustment, amount: 1.0) }

        before do
          allow(adjustments).to receive(:find_by).with(source_type: 'Spree::TaxRate').and_return(tax_adjustment)
        end

        it 'creates the payload with taxes' do
          expect(context.offers_details_payload).to include hash_including(taxes)
        end
      end

      context 'when box1 package info is supplied' do
        let(:product) { instance_double Spree::Product, box_properties: box_properties, property: nil, name: 'name1' }
        let(:product_2) { instance_double Spree::Product, box_properties: box_properties, property: nil, name: 'name2' }

        let(:boxes) do
          { 'order_line_additional_fields':
              [{ 'code': 'box1-packaged-weight', 'value': 6.0 },
               { 'code': 'box1-packaged-length', 'value': 12.3 },
               { 'code': 'box1-packaged-height', 'value': 46.36 },
               { 'code': 'box1-packaged-width-depth', 'value': 4.5 }] }
        end
        let(:box_properties) do
          [
            ['Box1 Packaged Weight', '6lbs'],
            ['Box1 Packaged Length', '12.3 inches'],
            ['Box1 Packaged Height', '46.36'],
            ['Box1 Packaged Width/Depth', '4.5"']
          ]
        end
        let(:cartonization_dimensions) do
          { 'order_line_additional_fields':
            [{ 'code': 'box1-packaged-height', 'value': 10.0 },
             { 'code': 'box1-packaged-length', 'value': 12.0 },
             { 'code': 'box1-packaged-width-depth', 'value': 8.0 },
             { 'code': 'box1-packaged-weight', 'value': 7.9 }] }
        end

        it 'creates the payload with dimensional data from the product' do
          expect(context.offers_details_payload).to include hash_including(boxes)
        end

        it 'calls legacy_box_data for each line_item' do
          context
          expect(interactor).to have_received(:legacy_box_data).twice
        end

        context 'when weight is not valid' do
          let(:box_properties) do
            [['Box1 Packaged Length', '12.3 inches'],
             ['Box1 Packaged Height', '46.36'],
             ['Box1 Packaged Width/Depth', '4.5"']]
          end

          let(:boxes) do
            { 'order_line_additional_fields':
                [{ 'code': 'box1-packaged-length', 'value': 12.3 },
                 { 'code': 'box1-packaged-height', 'value': 46.36 },
                 { 'code': 'box1-packaged-width-depth', 'value': 4.5 }] }
          end

          it 'excludes box1-packaged-weight from the order line addition fields' do
            expect(context.offers_details_payload).to include hash_including(boxes)
          end
        end

        context 'when cartonization is enabled for the vendor' do
          let(:cartonize_shipments) { true }

          it 'creates the payload with dimensional data from offer settings' do
            expect(context.offers_details_payload).to include hash_including(cartonization_dimensions)
            expect(interactor).to have_received(:cartonization_dimensions_for).twice
          end

          context 'when there is incomplete cartonization data' do
            let(:internal_package_dimensions) do
              { 'internal_package1' => { 'height' => '10.0', 'length' => '12.0', 'width' => '8.0', 'weight' => '' } }
            end

            before { context }

            it 'calls #legacy_box_data for the line item with missing data' do
              expect(interactor).to have_received(:legacy_box_data).once.with(line_item1)
            end
          end
        end
      end

      context 'when there are multiple boxes for the same item' do
        let(:product) { instance_double Spree::Product, box_properties: box_properties }

        let(:boxes) do
          { 'order_line_additional_fields':
              [{ 'code': 'box1-packaged-weight', 'value': 6.0 },
               { 'code': 'box1-packaged-length', 'value': 12.3 },
               { 'code': 'box1-packaged-height', 'value': 46.36 },
               { 'code': 'box1-packaged-width-depth', 'value': 4.5 },
               { 'code': 'box2-packaged-weight', 'value': 3.0 },
               { 'code': 'box2-packaged-length', 'value': 6.3 },
               { 'code': 'box2-packaged-height', 'value': 20.36 },
               { 'code': 'box2-packaged-width-depth', 'value': 2.5 },
               { 'code': 'number-of-boxes', 'value': 2 }] }
        end

        let(:box_properties) do
          [
            ['Box1 Packaged Weight', '6lbs'],
            ['Box1 Packaged Length', '12.3 inches'],
            ['Box1 Packaged Height', '46.36'],
            ['Box1 Packaged Width/Depth', '4.5"'],
            ['Box2 Packaged Weight', '3lbs'],
            ['Box2 Packaged Length', '6.3 inches'],
            ['Box2 Packaged Height', '20.36'],
            ['Box2 Packaged Width/Depth', '2.5"']
          ]
        end

        before do
          allow(product).to receive(:property).with('Number of Boxes').and_return(2)
          allow(product_2).to receive(:property).with('Number of Boxes').and_return(2)
        end

        it 'creates the payload with multiple box data' do
          expect(context.offers_details_payload).to include hash_including(boxes)
        end
      end

      context 'when shipping price is present' do
        context 'when the send_shipping_cost is true' do
          let(:send_shipping_cost) { true }
          let(:shipping_price) { 1.55 }

          it 'assign the shipping price to the order line' do
            expect(context.offers_details_payload).to include(hash_including(shipping_price: 0.78),
                                                              hash_including(shipping_price: 0.77))
          end
        end

        context 'when the send_shipping_cost is false' do
          let(:send_shipping_cost) { false }
          let(:shipping_price) { 1.55 }

          it 'assign the shipping price to the order line as 0.0' do
            expect(context.offers_details_payload).to include(hash_including(shipping_price: 0.0))
          end
        end
      end

      context 'when there is a promo on shipping' do
        let(:shipping_promo_total) { -10.0 }
        let(:shipping_price) { 15.0 }

        it 'reduces the shipping price by the shipping_promo_total' do
          expect(context.offers_details_payload).to include hash_including(shipping_price: 2.5)
        end
      end

      context 'when the vendor is a cost price vendor' do
        let(:cost_price_vendor) { true }
        let(:offer_settings_collection) { instance_double(ActiveRecord::Associations::CollectionProxy) }
        let(:offer_settings) { build_stubbed :offer_settings, cost_price: cost_price }
        let(:cost_price) { 4.0 }

        let(:total_cost_price) do
          { 'order_line_additional_fields':
              [{ code: MIRAKL_DATA[:order_line][:additional_fields][:total_cost_price],
                 value: 8.0 }] }
        end

        before do
          allow(variant).to receive(:offer_settings) { offer_settings_collection }
          allow(variant_2).to receive(:offer_settings) { offer_settings_collection }
          allow(offer_settings_collection).to receive(:find_by).with(vendor: vendor).and_return(offer_settings)
        end

        it 'creates the payload with the total cost price value' do
          expect(context.offers_details_payload).to include hash_including(total_cost_price)
        end
      end

      context 'when there is a mark down' do
        let(:discountable) { instance_double Spree::MarkDown, blank?: false, vendor_liability: 20.0 }

        let(:discountable_liability) do
          { 'order_line_additional_fields':
              [{ code: MIRAKL_DATA[:order_line][:additional_fields][:mark_down_liability],
                 value: 20.0 }] }
        end

        it 'sends the vendor liability to mirakl on the affected order line' do
          expect(context.offers_details_payload).to include hash_including(discountable_liability)
        end
      end

      context 'when there is a sale sku configuration' do
        let(:discountable) { instance_double Maisonette::SaleSkuConfiguration, vendor_liability: 20.0 }

        let(:discountable_liability) do
          { 'order_line_additional_fields':
              [{ code: MIRAKL_DATA[:order_line][:additional_fields][:mark_down_liability],
                 value: 20.0 }] }
        end

        it 'sends the vendor liability to mirakl on the affected order line' do
          expect(context.offers_details_payload).to include hash_including(discountable_liability)
        end
      end

      context 'when there is a monogram' do
        let(:monogram) do
          instance_double Spree::LineItemMonogram,
                          text: 'monogram text',
                          customization: monogram_customization
        end
        let(:monogram_customization) do
          { 'color' => { 'name' => 'Red', 'value' => 'Hex0r' },
            'font' => { 'name' => 'The Best Font', 'value' => 'comic sans' } }
        end

        let(:monogram_payload) do
          { 'order_line_additional_fields':
              [{ code: MIRAKL_DATA[:order_line][:additional_fields][:monogram][:text], value: 'monogram text' },
               { code: MIRAKL_DATA[:order_line][:additional_fields][:monogram][:color_hex], value: 'Hex0r' },
               { code: MIRAKL_DATA[:order_line][:additional_fields][:monogram][:color_name], value: 'Red' },
               { code: MIRAKL_DATA[:order_line][:additional_fields][:monogram][:font_family], value: 'comic sans' },
               { code: MIRAKL_DATA[:order_line][:additional_fields][:monogram][:font_name], value: 'The Best Font' }] }
        end

        it 'sends the monogram to mirakl on the affected order line' do
          expect(context.offers_details_payload).to include hash_including(monogram_payload)
        end

        context 'with empty customization' do
          let(:monogram_customization) { {} }

          it "doesn't produce an empty payload" do
            expect(context.offers_details_payload).not_to be_nil
          end
        end
      end
    end

    context 'when the line item amount is 0.0' do
      let(:context) { described_class.call(commercial_order: mirakl_commercial_order, resubmit: false) }
      let(:line_item1) do
        instance_double Spree::LineItem,
                        price: 0.0,
                        amount: 0.0,
                        quantity: 2,
                        mirakl_offer_id: mirakl_offer.offer_id,
                        sku: 'SKU123'
      end

      let(:error_message) do
        I18n.t('errors.mirakl_zero_amount_order_submit',
               sku: line_item1.sku,
               mirakl_offer_id: line_item1.mirakl_offer_id)
      end

      it 'fails the interactor' do
        expect(context).to be_failure
        expect(context.exception.message).to eq error_message
      end
    end
  end

  describe '#raise_zero_price' do
    let(:raise_zero_price) { described_class.new(resubmit: resubmit).send(:raise_zero_price, line_item) }
    let(:line_item) { instance_double Spree::LineItem, sku: 'SOMESKU', mirakl_offer_id: '2002' }

    context 'when resubmit is true' do
      let(:resubmit) { true }

      it 'returns nil' do
        expect(raise_zero_price).to eq nil
      end
    end

    context 'when resubmit is false' do
      let(:resubmit) { false }
      let(:error_message) do
        I18n.t('errors.mirakl_zero_amount_order_submit',
               sku: line_item.sku,
               mirakl_offer_id: line_item.mirakl_offer_id)
      end

      it 'raises an exception' do
        expect { raise_zero_price }.to raise_error(StandardError, error_message)
      end
    end
  end
end
