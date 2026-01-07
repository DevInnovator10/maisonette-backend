# frozen_string_literal: true

module Algolia
    class SyncProductWorker
    include Sidekiq::Worker

    sidekiq_options lock: :until_and_while_executing,
                    retry: true

    def perform(algolia_product_id, remove)
      if remove
        index = Syndication::Product.algolia_index
        index.delete_object(algolia_product_id)
      else
        syndication_product = Syndication::Product.find_by!(master_or_variant_id: algolia_product_id)
        syndication_product.index!
      end
    end
  end
end
