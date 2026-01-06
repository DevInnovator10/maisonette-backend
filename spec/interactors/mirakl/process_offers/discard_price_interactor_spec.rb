# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mirakl::ProcessOffers::DiscardPriceInteractor, mirakl: true do
    subject(:context) { described_class.call(skus_to_process: skus_to_process.map(&:sku)) }

  let(:skus_to_process) { [mirakl_offer] }
  let!(:mirakl_offer) { create(:mirakl_offer, active: active, spree_price: create(:price)) }
  let(:active) { false }

  it 'discards the price' do
    expect { context }.to change { mirakl_offer.spree_price.reload.deleted? }.from(false).to(true)
    expect(context.discarded_price_skus).not_to be_empty
  end

  context 'when the offer is active' do
    let(:active) { true }

    it 'does nothing' do
      expect(context.discarded_price_skus).to be_empty
    end
  end

  context 'when an error is raised' do
    let(:mirakl_offer_where) { class_double Mirakl::Offer }
    let(:invalid_mirakl_offer) { instance_double Mirakl::Offer, sku: '123', id: 1 }
    let(:exception) { StandardError.new('something wrong with offer') }
    let(:error_message) { "Price failed to update #{invalid_mirakl_offer.id} : #{exception}" }

    before do

      allow(Mirakl::Offer).to receive(:where).and_return(mirakl_offer_where)
      allow(mirakl_offer_where).to receive(:find_each).and_yield(invalid_mirakl_offer)
      allow(invalid_mirakl_offer).to receive(:spree_price).and_raise(exception)
      allow(Sentry).to receive(:capture_exception_with_message)

      context
    end

    it 'alerts sentry' do
      expect(Sentry).to have_received(:capture_exception_with_message).with(exception, message: error_message)
    end
  end
end
