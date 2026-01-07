# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::UpdateOfferDiscountPricesWorker, mirakl: true do
  describe '#perform' do
    subject(:perform) { worker.perform(product_ids) }

    let(:worker) { described_class.new }
    let(:product_ids) { [1, 2, 3] }
    let(:offer_csv) do
      "sku,shop-id,product-id,product-id-type,state,discount-start-date,discount-end-date,discount-price\n"
    end
    let(:offer_export_job) { instance_double(Salsify::MiraklOfferExportJob, offers: active_storage) }
    let(:active_storage) { instance_double(ActiveStorage::Attached::One) }

    before do
      allow(worker).to receive(:generate_csv_with_headers).and_return(offer_csv)
      allow(worker).to receive(:generate_csv_rows).with(product_ids)
      allow(Salsify::MiraklOfferExportJob).to receive(:create) { offer_export_job }
      allow(active_storage).to receive(:attach).with(
        io: 'StringIO',
        filename: 'solidus_onsale_offers.csv',
        content_type: 'text/csv'
      ) { offer_export_job }
      allow(offer_export_job).to receive(:send_offers_to_mirakl)
      allow(StringIO).to receive(:new).with(offer_csv).and_return('StringIO')
    end

    context 'when it is successful' do
      let(:exception) {}

      before { perform }

      it 'processes the product_ids' do
        expect(worker).to have_received(:generate_csv_with_headers)
        expect(worker).to have_received(:generate_csv_rows)
        expect(offer_export_job).to have_received(:send_offers_to_mirakl)
      end
    end
  end

  describe '#generate_csv_with_headers' do
    subject(:generate_csv_with_headers) { worker.send :generate_csv_with_headers }

    let(:worker) { described_class.new }

    it 'creates a headers row' do
      expect(generate_csv_with_headers).to eq 'sku,shop-id,product-id,product-id-type,' \
                                              "state,discount-start-date,discount-end-date,discount-price\n"
    end
  end

  describe '#offers_to_update' do
    subject(:offers_to_update) { worker.send :offers_to_update, product_ids }

    let(:worker) { described_class.new }
    let(:product_ids) { [product_1.id, product_2.id] }
    let(:product_1) { create :product }
    let(:product_2) { create :product }
    let(:variant_1) { create :variant, prices: [variant_1_price] }
    let(:variant_2) { create :variant, prices: [variant_2_price] }
    let(:variant_3) { create :variant, prices: [variant_3_price] }
    let(:offer_1) { create :mirakl_offer, price: 5.50 }
    let(:offer_2) { create :mirakl_offer, price: 5.50 }
    let(:offer_3) { create :mirakl_offer, price: 5.50 }
    let(:variant_1_price) { create :price, amount: 4.50, mirakl_offer: offer_1 }
    let(:variant_2_price) { create :price, amount: 5.50, mirakl_offer: offer_2 }
    let(:variant_3_price) { create :price, amount: 6.50, mirakl_offer: offer_3 }

    before do
      [product_1, product_2].each(&:prices).each(&:delete)
      Mirakl::Offer.delete_all
      product_1.variants << variant_1
      product_2.variants << [variant_2, variant_3]
    end

    it 'returns offers for the given product ids that have a different spree price compared to offer price' do
      expect(offers_to_update).to match_array([offer_1, offer_3])
    end
  end

  describe '#generate_csv_rows', freeze_time: Time.zone.local(2021, 2, 24, 5) do
    subject(:generate_csv_rows) { worker.send :generate_csv_rows, product_ids }

    let(:worker) { described_class.new }
    let(:offer_1) do
      instance_double Mirakl::Offer, spree_price: spree_price_1, sku: 'MAIS1234', shop: shop_1,
                                     original_price: 10.0, quantity: 10
    end
    let(:shop_1) { instance_double Mirakl::Shop, shop_id: 2001, id: 10 }
    let(:shop_2) { instance_double Mirakl::Shop, shop_id: 2002, id: 11 }
    let(:spree_price_1) { instance_double Spree::Price, offer_settings: offer_settings_1, active_sale: sale_price_1 }
    let(:offer_settings_1) { instance_double Spree::OfferSettings, vendor_sku: 'a-dress-1' }
    let(:sale_price_1) do
      instance_double Spree::SalePrice,
                      calculated_price: 5.0,
                      start_at: (Date.current + 1.day).beginning_of_day,
                      end_at: (Date.current + 2.days).beginning_of_day
    end
    let(:offer_2) do
      instance_double Mirakl::Offer, spree_price: spree_price_2, sku: 'MAIS4321',
                                     shop: shop_2, original_price: 20.0, quantity: 20
    end
    let(:spree_price_2) { instance_double Spree::Price, offer_settings: offer_settings_2, active_sale: sale_price_2 }
    let(:offer_settings_2) { instance_double Spree::OfferSettings, vendor_sku: 'a-dress-2' }
    let(:sale_price_2) do
      instance_double Spree::SalePrice,
                      calculated_price: 15.0,
                      start_at: nil,
                      end_at: nil
    end
    let(:csv_offers_rows) do
      ["a-dress-1,2001,MAIS1234,SKU,11,2021-02-25T00:00:00-05:00,2021-02-26T00:00:00-05:00,5.0\n", \
       "a-dress-2,2002,MAIS4321,SKU,11,,,15.0\n"]
    end
    let(:product_ids) { [1, 2, 3] }
    let(:offers_to_update) { [offer_1, offer_2] }

    before do
      worker.instance_variable_set(:@offers_csv, [])
      allow(worker).to receive(:offers_to_update).and_return(offers_to_update)
    end

    it 'returns a csv row of values' do
      generate_csv_rows

      expect(worker.instance_variable_get('@offers_csv')).to match_array(csv_offers_rows)
    end

    context 'when there is an error' do
      let(:standard_error) { StandardError.new 'error on offer 1' }
      let(:error_message) { "Unable to update mirakl discount price for offer sku - #{offer_1.sku}" }
      let(:csv_offer_row) do
        ["a-dress-2,2002,MAIS4321,SKU,11,,,15.0\n"]
      end

      before do
        allow(offer_1).to receive(:spree_price).and_raise(standard_error)
        allow(Sentry).to receive(:capture_exception_with_message)
      end

      it 'returns array of successful offer payloads' do
        generate_csv_rows

        expect(worker.instance_variable_get('@offers_csv')).to match_array(csv_offer_row)
      end

      it 'calls Sentry.capture_exception_with_message with the failed offer sku' do
        generate_csv_rows

        expect(Sentry).to have_received(:capture_exception_with_message).with(standard_error, message: error_message)
      end
    end
  end
end
