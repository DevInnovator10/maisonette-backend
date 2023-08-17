# frozen_string_literal: true

module Maisonette
    class UpdateVariantImagesWorker
    include Sidekiq::Worker

    sidekiq_options retry: 0, queue: 'default'

    # Input:
    # - styles [required]: image styles to reprocess, comma separated (ex. "mini,large,zoom")
    # - size: batch size for workers
    # Output:
    # - number of batches
    def perform(styles, size = 50)
      batch_size = size.to_i
      batches = (Spree::Variant.count / batch_size.to_f).ceil
      batches.times do |index|
        ::Maisonette::UpdateVariantImagesBatchWorker.perform_async(styles, index, batch_size)
      end
    end
  end
end
