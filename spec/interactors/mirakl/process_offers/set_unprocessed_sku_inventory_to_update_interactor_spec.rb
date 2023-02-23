# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessOffers::SetUnprocessedSkuInventoryToUpdateInteractor, mirakl: true do
  subject(:context) { described_class.call(params) }

  let(:params) do
    {
      skus: %w[variant-updated variant-with-price-error variant-with-stock-error],
      updated_offer_inventory_skus: ['variant-updated'],
      updated_price_skus: %w[variant-updated variant-with-stock-error]
    }
  end
  let(:mirakl_offer_1) { create :mirakl_offer, quantity: 5 }
  let(:mirakl_offer_2) { create :mirakl_offer, quantity: 10 }

  before do
    allow(Mirakl::Offer).to receive(:find_by).with(sku: 'variant-with-stock-error').and_return(mirakl_offer_1)
    allow(Mirakl::Offer).to receive(:find_by).with(sku: 'variant-with-price-error').and_return(mirakl_offer_2)

    context
  end

  it 'adds context for offers inventory to update that have not been processed' do
    expect(context.offers_inventory_to_update).to match_array([mirakl_offer_1, mirakl_offer_2])
  end

  it 'sets the inventory for the offers to 0, but does not save it' do
    expect(mirakl_offer_1.quantity).to eq 0
    expect(mirakl_offer_2.quantity).to eq 0

    expect(mirakl_offer_1.reload.quantity).to eq 5
    expect(mirakl_offer_2.reload.quantity).to eq 10
  end
end
