# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::BreakSalePriceCacheWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform }

    let(:redis_url) { "#{Maisonette::Config.fetch('redis.service_url')}/#{Maisonette::Config.fetch('redis.db')}" }
    let(:redis) { instance_double Redis, smembers: redis_sale_price_ids, del: true, sadd: true }
    let(:redis_key) { 'active_sale_price_ids' }
    let(:active_sale_prices) { class_double Spree::SalePrice, ids: active_sale_price_ids }
    let(:changed_sale_prices) { class_double Spree::SalePrice }
    let(:changed_sale_prices_array) { [sale_price1, sale_price2] }
    let(:sale_price1) { instance_double Spree::SalePrice, touch: true }
    let(:sale_price2) { instance_double Spree::SalePrice, touch: true }

    let(:active_sale_price_ids) { [] }
    let(:redis_sale_price_ids) { [] }

    before do
      allow(Redis).to receive(:new).and_return(redis)
      allow(Spree::SalePrice).to receive(:active).and_return(active_sale_prices)
      allow(Spree::SalePrice).to receive(:where).and_return(changed_sale_prices)
      allow(changed_sale_prices).to receive(:find_each).and_yield(sale_price1).and_yield(sale_price2)

      perform
    end

    it 'creates a redis instance' do
      expect(Redis).to have_received(:new).with(url: redis_url)
    end

    context 'when there are no active sale prices or redis sale prices' do
      let(:active_sale_price_ids) { [] }
      let(:redis_sale_price_ids) { [] }

      it 'does not touch anything' do
        expect(Spree::SalePrice).not_to have_received(:where)
      end

      it 'does not update redis' do
        expect(redis).not_to have_received(:del)
        expect(redis).not_to have_received(:sadd)
      end
    end

    context 'when there are active sale prices and redis sale prices' do
      let(:active_sale_price_ids) { [1, 2, 3, 4] }
      let(:redis_sale_price_ids) { %w[2 4 5] }

      it 'touches the sale prices that are missing or extra from redis' do
        expect(Spree::SalePrice).to have_received(:where).with(id: %w[5 1 3])
        expect(changed_sale_prices_array).to all have_received(:touch)
      end

      it 'does update redis' do
        expect(redis).to have_received(:del).with(redis_key)
        expect(redis).to have_received(:sadd).with(redis_key, active_sale_price_ids.map(&:to_s))
      end
    end

    context 'when there are no active sale prices but there are redis sale prices' do
      let(:active_sale_price_ids) { [1, 2, 3, 4] }
      let(:redis_sale_price_ids) { [] }

      it 'touches the sale prices that are missing or extra from redis' do
        expect(Spree::SalePrice).to have_received(:where).with(id: %w[1 2 3 4])
        expect(changed_sale_prices_array).to all have_received(:touch)
      end

      it 'does update redis' do
        expect(redis).to have_received(:del).with(redis_key)
        expect(redis).to have_received(:sadd).with(redis_key, active_sale_price_ids.map(&:to_s))
      end
    end

    context 'when there are active prices but no redis sale prices' do
      let(:active_sale_price_ids) { [] }
      let(:redis_sale_price_ids) { %w[2 4 5] }

      it 'touches the sale prices that are missing or extra from redis' do
        expect(Spree::SalePrice).to have_received(:where).with(id: %w[2 4 5])
        expect(changed_sale_prices_array).to all have_received(:touch)
      end

      it 'does update redis' do
        expect(redis).to have_received(:del).with(redis_key)
        expect(redis).not_to have_received(:sadd)
      end
    end
  end
end
