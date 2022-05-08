# frozen_string_literal: true

module Syndication
    class ProductsWorker < BaseWorker
    def perform(last_update = nil)
      initialize_jobs(last_update)
    end

    private

    def initialize_jobs(last_update)
      started_at = Time.current
      workers = spawn_workers(last_update)
      Syndication::ProductUpdate.create!(started_at: started_at)
      workers
    end

    def spawn_workers(last_update)
      last_update ||= Syndication::ProductUpdate.last_update

      product_ids = products_query(last_update).find_each.map(&:id)
      product_ids.each_slice(20).map do |sliced_product_ids|
        [SplitProductsWorker.perform_async(sliced_product_ids), sliced_product_ids]
      end
    end

    def products_query(last_update)
      last_update ||= Date.new(2019)
      Spree::Product.where('spree_products.updated_at >= ?', last_update).with_deleted
    end
  end
end
