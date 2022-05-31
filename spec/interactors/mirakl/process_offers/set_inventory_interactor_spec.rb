# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessOffers::SetInventoryInteractor, mirakl: true do
  subject(:context) { described_class.call(offers_inventory_to_update: [mirakl_offer]) }

  let(:mirakl_offer) do
    create(:mirakl_offer, :best, sku: offer_settings.maisonette_sku, quantity: 100, shop: mirakl_shop)
  end
  let(:mirakl_shop) { create(:mirakl_shop, :with_stock_location, spree_stock_location: stock_item.stock_location) }
  let(:stock_item) { variant.stock_items.first }
  let(:stock_movement) { Spree::StockMovement.last }
  let(:stock_location) { create(:stock_location) }
  let(:offer_settings) { create :offer_settings, variant: variant, vendor: stock_location.vendor }
  let(:variant) { create(:variant, :in_stock, count_on_hand: 0, stock_location: stock_location) }

  before do
    allow(Sentry).to receive(:capture_exception_with_message).and_return(true)
  end

  it 'sets the right data on stock movement' do
    expect { context }.to change { Spree::StockMovement.count }.by(1)
    expect(context).to be_a_success
    expect(stock_movement.originator).to eq mirakl_offer
    expect(stock_movement.quantity).to eq 100
    expect(Sentry).not_to have_received(:capture_exception_with_message)
  end

  it 'sets the count on hand on the stock item' do
    expect { context }.to change { stock_item.reload.count_on_hand }.by(100)
    expect(context).to be_a_success
    expect(Sentry).not_to have_received(:capture_exception_with_message)
  end

  context 'when the offer_settings is discarded' do
    let(:offer_settings) do
      create(
        :offer_settings,
        variant: variant,
        vendor: stock_location.vendor,
        discarded_at: Time.current
      )
    end

    it 'sets the right data on stock movement' do
      expect { context }.to change { Spree::StockMovement.count }.by(1)
      expect(context).to be_a_success
      expect(stock_movement.originator).to eq mirakl_offer
      expect(stock_movement.quantity).to eq 100
      expect(Sentry).not_to have_received(:capture_exception_with_message)
    end

    it 'sets the count on hand on the stock item' do
      expect { context }.to change { stock_item.reload.count_on_hand }.by(100)
      expect(context).to be_a_success
      expect(Sentry).not_to have_received(:capture_exception_with_message)
    end
  end

  context 'when there are no variant' do
    let(:mirakl_offer) { create(:mirakl_offer, :best, sku: 'missing-sku', quantity: 100, shop: mirakl_shop) }

    it 'returns success but not logs the exception' do
      expect(context).to be_a_success

      expect(Sentry).not_to have_received(:capture_exception_with_message)
    end

    it "doesn't put the sku to updated_offer_inventory_skus" do
      expect(context.updated_offer_inventory_skus).not_to include 'missing-sku'
    end
  end

  context 'when stock movement create! fails' do
    before do
      allow(Spree::StockMovement).to receive(:create!) { raise 'general error' }
    end

    it 'returns success but logs the exception' do
      expect(context).to be_a_success

      expect(Sentry).to have_received(:capture_exception_with_message).with(
        kind_of(RuntimeError),
        hash_including(:message)
      )
    end
  end

  context 'when stock item find_or_create_by! fails' do
    let(:stubbed_join) { instance_double('Spree::StockItem') }

    before do
      stock_item = class_double(Spree::StockItem)
      allow(stock_item).to receive(:find_or_create_by!) { raise 'general error' }
      allow(Spree::StockItem).to receive(:joins).and_call_original
      allow(Spree::StockItem).to receive(:joins).with(:variant).and_return(stock_item)
    end

    it 'returns success but logs the exception' do
      expect(context).to be_a_success

      expect(Sentry).to have_received(:capture_exception_with_message).with(
        kind_of(RuntimeError),
        hash_including(:message)
      )
    end
  end

  context 'when there are no stock item' do
    let(:stock_items_for_variant) do
      offer_settings = Spree::OfferSettings.find_by(maisonette_sku: mirakl_offer.sku)
      offer_settings.variant.stock_items.where(stock_location: mirakl_offer.shop.stock_location)
    end

    before do
      stock_item.delete
    end

    it 'creates the stock item' do
      expect { context }.to change(stock_items_for_variant, :count).by(1)
      expect(context).to be_a_success

      expect(Sentry).not_to have_received(:capture_exception_with_message)
    end
  end

  context 'when there are an error with one of the provided variants' do
    subject(:context) { described_class.call(offers_inventory_to_update: [mirakl_offer, offer_without_variant]) }

    let(:offer_without_variant) { create(:mirakl_offer, :best, sku: 'not-found', quantity: 100, shop: mirakl_shop) }

    it 'sets the count on hand on the stock item' do
      expect { context }.to change(Spree::StockItem, :count).by(1)
      expect(context).to be_a_success

      expect(Sentry).not_to have_received(:capture_exception_with_message)
    end

    it 'processes just the variant without error' do
      expect(context.updated_offer_inventory_skus).to contain_exactly mirakl_offer.sku
    end
  end
end
