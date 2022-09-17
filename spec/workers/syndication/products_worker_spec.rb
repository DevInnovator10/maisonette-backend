# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Syndication::ProductsWorker do
    describe '#perform' do
    subject(:perform) { worker.perform }

    let(:worker) { described_class.new }

    before do
      allow(worker).to receive(:initialize_jobs)

      perform
    end

    it 'calls initialize_jobs' do
      expect(worker).to have_received(:initialize_jobs)
    end
  end

  describe '#initialize_jobs', freeze_time: true do
    subject(:initialize_jobs) { product_worker.send(:initialize_jobs, last_update) }

    let(:product_worker) { described_class.new }
    let(:last_update) { Time.current - 10.minutes }
    let(:started_at) { Time.current }
    let(:sidekiq_jobs) { [['jid1', [1, 2]], ['jid2', [3, 4]], ['jid3', [5, 6]]] }

    before do
      allow(product_worker).to receive_messages(spawn_workers: sidekiq_jobs)
      allow(Syndication::ProductUpdate).to receive_messages(create!: true)

      initialize_jobs
    end

    it 'calls spawn_workers' do
      expect(product_worker).to have_received(:spawn_workers).with(last_update)
    end

    it 'creates Syndication::ProductSyndicationUpdate with the started_at' do
      expect(Syndication::ProductUpdate).to have_received(:create!).with(started_at: started_at)
    end

    it 'returns the sidekiq_jobs from spawn_workers' do
      expect(initialize_jobs).to eq sidekiq_jobs
    end
  end

  describe '#spawn_workers' do
    subject(:spawn_workers) { worker.send(:spawn_workers, last_update) }

    let(:worker) { described_class.new }
    let(:last_update) { Time.current - 10.minutes }
    let(:updated_products) { class_double Spree::Product, find_each: products }
    let(:products) do
      Array.new(25).map.with_index(1) do |_, i|
        instance_double Spree::Product, id: i
      end
    end
    let(:sidekiq_jobs) do
      [['jid1', (1..20).to_a],
       ['jid2', (21..25).to_a],]
    end

    before do
      allow(worker).to receive_messages(products_query: updated_products)
      allow(Syndication::SplitProductsWorker).to receive(:perform_async).and_return('jid1', 'jid2')

      spawn_workers
    end

    it 'calls products_query with last_update' do
      expect(worker).to have_received(:products_query).with(last_update)
    end

    it 'creates SplitProductsWorkers' do
      expect(Syndication::SplitProductsWorker).to have_received(:perform_async).with((1..20).to_a)
      expect(Syndication::SplitProductsWorker).to have_received(:perform_async).with((21..25).to_a)
    end

    it 'returns the spawned workers' do
      expect(spawn_workers).to eq sidekiq_jobs
    end
  end

  describe '#products_query' do
    subject(:products_query) { described_class.new.send(:products_query, last_update) }

    let(:products) { class_double Spree::Product, with_deleted: with_deleted_products }
    let(:with_deleted_products) { [instance_double(Spree::Product), instance_double(Spree::Product)] }

    before do
      allow(Spree::Product).to receive_messages(where: products)
    end

    context 'when the last_update is passed' do
      let(:last_update) { Time.current }

      it 'queries spree products with the passed in last_update' do
        expect(products_query).to eq with_deleted_products
        expect(Spree::Product).to have_received(:where).with('spree_products.updated_at >= ?', last_update)
      end
    end

    context 'when the last_update is nil' do
      let(:last_update) { nil }

      it 'queries for all products' do
        expect(products_query).to eq with_deleted_products
        expect(Spree::Product).to have_received(:where).with('spree_products.updated_at >= ?', Date.new(2019))
      end
    end
  end
end
