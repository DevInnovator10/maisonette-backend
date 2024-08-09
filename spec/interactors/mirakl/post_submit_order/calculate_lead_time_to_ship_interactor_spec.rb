# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::PostSubmitOrder::CalculateLeadTimeToShipInteractor, mirakl: true do
  describe 'calculate_lead_time_to_ship.ship_by' do
    let(:calculate_lead_time_to_ship) do
      described_class.new(shipment: shipment, created_date: Time.zone.parse(created_date))
    end
    let(:shipment) { instance_double Spree::Shipment, mirakl_shop: mirakl_shop, number: 'H1234', order: order }
    let(:order) { instance_double Spree::Order, number: 'R1234' }
    let(:mirakl_shop) do
      instance_double Mirakl::Shop,
                      fulfil_by_eod_cutoff_time: fulfil_by_eod_cutoff_time,
                      lead_time_ship_leniency: lead_time_ship_leniency,
                      working_hr_start_time: working_hr_start_time
    end
    let(:fulfil_by_eod_cutoff_time) { '1530' }
    let(:working_hr_start_time) { '830' }
    let(:lead_time_ship_leniency) { 0 }
    let(:max_variant_lead) { 2 }
    let(:created_date) { '2018-11-14 11:00' }

    # 2018-11-14 - Wednesday
    # 2018-11-15 - Thursday
    # 2018-11-16 - Friday
    # 2018-11-17 - Saturday
    # 2018-11-18 - Sunday
    # 2018-11-19 - Monday
    # 2018-11-20 - Tuesday
    # 2018-11-21 - Wednesday
    # 2018-11-22 - Thursday
    # 2018-11-23 - Friday

    context 'when it is successful' do
      before do
        allow(calculate_lead_time_to_ship).to receive_messages(max_variant_lead: max_variant_lead)

        calculate_lead_time_to_ship.call
      end

      context 'when the order is placed on Wednesday 14th 11:00' do
        let(:created_date) { '2018-11-14 11:00' }

        it 'equals Friday 16th 11:00' do
          expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-16 11:00')
        end

        context 'when max_variant_lead is 3 days' do
          let(:max_variant_lead) { 3 }

          it 'equals Monday 19th 11:00' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-19 11:00')
          end
        end

        context 'when max_variant_lead is 4 days' do
          let(:max_variant_lead) { 4 }

          it 'equals Tuesday 20th 11:00' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-20 11:00')
          end
        end

        context 'when lead_time_ship_leniency is 2 days' do
          let(:lead_time_ship_leniency) { 2 }

          it 'equals Tuesday 20th 11:00' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-20 11:00')
          end
        end
      end

      context 'when the order is placed on Wednesday 14th 06:00' do
        let(:created_date) { '2018-11-14 06:00' }
        let(:working_hr_start_time) { '830' }

        it 'equals Friday 16th 08:30' do
          expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-16 08:30')
        end

        context 'when working_hr_start_time is 09:30' do
          let(:working_hr_start_time) { '930' }

          it 'equals Friday 16th 09:30' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-16 09:30')
          end
        end

        context 'when max_variant_lead is 3 days' do
          let(:max_variant_lead) { 3 }

          it 'equals Monday 19th 08:30' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-19 08:30')
          end
        end

        context 'when max_variant_lead is 4 days' do
          let(:max_variant_lead) { 4 }

          it 'equals Tuesday 20th 08:30' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-20 08:30')
          end
        end

        context 'when lead_time_ship_leniency is 2 days' do
          let(:lead_time_ship_leniency) { 2 }

          it 'equals Tuesday 20th 08:30' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-20 08:30')
          end
        end
      end

      context 'when the order is placed on Wednesday 14th 17:00' do
        let(:created_date) { '2018-11-14 17:00' }
        let(:fulfil_by_eod_cutoff_time) { '1530' }

        it 'equals Friday 16th 23:59' do
          expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-16 23:59:59.999999999')
        end

        context 'when max_variant_lead is 3 days' do
          let(:max_variant_lead) { 3 }

          it 'equals Monday 19th 23:59' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-19 23:59:59.999999999')
          end
        end

        context 'when max_variant_lead is 4 days' do
          let(:max_variant_lead) { 4 }

          it 'equals Tuesday 20th 23:59' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-20 23:59:59.999999999')
          end
        end

        context 'when lead_time_ship_leniency is 2 days' do
          let(:lead_time_ship_leniency) { 2 }

          it 'equals Tuesday 20th 23:59' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-20 23:59:59.999999999')
          end
        end
      end

      context 'when the order is placed on Saturday 17th 11:00' do
        let(:created_date) { '2018-11-17 11:00' }
        let(:working_hr_start_time) { '830' }

        it 'equals Wednesday 21st 08:30' do
          expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-21 08:30')
        end

        context 'when working_hr_start_time is 09:30' do
          let(:working_hr_start_time) { '930' }

          it 'equals Wednesday 21st 09:30' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-21 09:30')
          end
        end

        context 'when lead_time_ship_leniency is 2 days' do
          let(:lead_time_ship_leniency) { 2 }

          it 'equals Friday 23th 08:30' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-23 08:30')
          end

          context 'when max_variant_lead is 4 days' do
            let(:max_variant_lead) { 4 }

            it 'equals Tuesday 27th 08:30' do
              expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-27 08:30')
            end
          end
        end
      end

      context 'when there is one holiday between placing day and ship_by' do
        let(:created_date) { '2020-12-31 8:30' }

        context 'when the order is placed on Thursday 31st Dec 2020' do
          let(:working_hr_start_time) { '830' }

          it 'equals Tuesday 5th 08:30' do
            expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2021-01-05 08:30')
          end

          context 'when working_hr_start_time is 09:30' do
            let(:working_hr_start_time) { '930' }

            it 'equals Tuesday 5th 09:30' do
              expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2021-01-05 09:30')
            end
          end

          context 'when lead_time_ship_leniency is 2 days' do
            let(:lead_time_ship_leniency) { 2 }

            it 'equals Friday 23th 08:30' do
              expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2021-01-07 08:30')
            end

            context 'when max_variant_lead is 4 days' do # rubocop:disable RSpec/NestedGroups
              let(:max_variant_lead) { 4 }

              it 'equals Tuesday 27th 08:30' do
                expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2021-01-11 08:30')
              end
            end
          end
        end
      end
    end

    context 'when it fails' do
      let(:exception) { StandardError.new('something went wrong') }
      let(:error_message) do
        "Order number: #{shipment.order.number}\nShipment Number: #{shipment.number}"
      end

      before do
        allow(calculate_lead_time_to_ship).to receive(:max_variant_lead).and_raise(exception)
        allow(calculate_lead_time_to_ship).to receive(:rescue_and_capture)

        calculate_lead_time_to_ship.call
      end

      it 'rescues and captures the exception' do
        expect(calculate_lead_time_to_ship).to(
          have_received(:rescue_and_capture).with(exception,
                                                  error_details: error_message)
        )
      end
    end
  end

  describe 'max_variant_lead' do
    let(:stock_location) { create(:stock_location) }
    let(:mirakl_shop) { create(:mirakl_shop, :with_stock_location, spree_stock_location: stock_location) }
    let(:calculate_lead_time_to_ship) do
      described_class.new(shipment: shipment, created_date: Time.zone.parse('2018-11-14 11:00'))
    end
    let(:shipment) { instance_double Spree::Shipment, manifest: manifest, mirakl_shop: mirakl_shop }
    let(:manifest) { [item_1, item_2] }
    let(:item_1) do
      instance_double Spree::ShippingManifest::ManifestItem,
                      variant: instance_double(Spree::Variant, lead_time: lead_time_1),
                      line_item: line_item_1
    end
    let(:item_2) do
      instance_double Spree::ShippingManifest::ManifestItem,
                      variant: instance_double(Spree::Variant, lead_time: lead_time_2),
                      line_item: line_item_2
    end
    let(:lead_time_1) { nil }
    let(:lead_time_2) { nil }
    let(:default_lead_time) { 2 }
    let(:line_item_1) { create(:line_item, id: '123') }
    let(:line_item_2) { create(:line_item, id: '456') }

    before do
      ENV['DEFAULT_LEAD_TIME'] = default_lead_time.to_s
      calculate_lead_time_to_ship.call
    end

    context 'when lead time is less than the default_lead_time' do
      it 'returns the default_lead_time' do
        expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-16 11:00')
      end
    end

    context 'when lead time is greater or equal than the default_lead_time' do
      let(:lead_time_1) { 2 }
      let(:lead_time_2) { 5 }

      it 'returns the highest lead time' do
        expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-21 11:00')
      end
    end

    context 'when item is monogrammable' do
      let(:shipment) { instance_double Spree::Shipment, manifest: manifest, mirakl_shop: mirakl_shop }
      let(:stock_location) { create(:stock_location) }
      let(:mirakl_shop) { create(:mirakl_shop, :with_stock_location, spree_stock_location: stock_location) }
      let(:manifest) { [item] }
      let(:item) do
        instance_double Spree::ShippingManifest::ManifestItem,
                        variant: variant,
                        line_item: line_item
      end
      let(:variant) do
        create :variant,
               lead_time: 2,
               prices: [create(:price, vendor: vendor)],
               offer_settings: [offer_settings]
      end
      let(:vendor) { create(:vendor, name: 'Cool Vendor') }
      let(:line_item) { create(:line_item, variant: variant, vendor: vendor) }
      let(:offer_settings) do
        create :offer_settings,
               monogrammable: true,
               monogram_lead_time: 3,
               monogram_price: 8.99,
               monogram_cost_price: 2.99,
               vendor: vendor
      end

      before do
        calculate_lead_time_to_ship.call
      end

      it 'equals Wednesday 21st 11:00' do
        expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-21 11:00')
      end
    end

    context 'when non monogram item has longer lead time' do
      let(:shipment) { instance_double Spree::Shipment, manifest: manifest, mirakl_shop: mirakl_shop }
      let(:stock_location) { create(:stock_location) }
      let(:mirakl_shop) { create(:mirakl_shop, :with_stock_location, spree_stock_location: stock_location) }
      let(:manifest) { [item_1, item_2] }
      let(:item_1) do
        instance_double Spree::ShippingManifest::ManifestItem,
                        variant: variant_1,
                        line_item: line_item_1
      end
      let(:variant_1) do
        create :variant,
               lead_time: 2,
               prices: [create(:price, vendor: vendor_1)],
               offer_settings: [offer_settings]
      end
      let(:vendor_1) { create(:vendor, name: 'Cool Vendor') }
      let(:line_item_1) { create(:line_item, variant: variant_1, vendor: vendor_1) }
      let(:offer_settings) do
        create :offer_settings,
               monogrammable: true,
               monogram_lead_time: 3,
               monogram_price: 8.99,
               monogram_cost_price: 2.99,
               vendor: vendor_1
      end
      let(:item_2) do
        instance_double Spree::ShippingManifest::ManifestItem,
                        variant: variant_2,
                        line_item: line_item_2
      end
      let(:variant_2) do
        create :variant,
               lead_time: 10,
               prices: [create(:price, vendor: vendor_2)],
               offer_settings: [offer_settings_2]
      end
      let(:vendor_2) { create(:vendor, name: 'Stupid Vendor') }
      let(:line_item_2) { create(:line_item, variant: variant_2, vendor: vendor_2) }
      let(:offer_settings_2) { create(:offer_settings, monogrammable: false) }

      before do
        calculate_lead_time_to_ship.call
      end

      it 'equals Wednesday 28th 11:00' do
        expect(calculate_lead_time_to_ship.context.ship_by).to eq Time.zone.parse('2018-11-28 11:00')
      end
    end
  end
end
