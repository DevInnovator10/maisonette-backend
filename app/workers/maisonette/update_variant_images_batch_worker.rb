# frozen_string_literal: true

module Maisonette
  class UpdateVariantImagesBatchWorker
    include Sidekiq::Worker

    sidekiq_options retry: 0, queue: 'default'

    # Input:
    # - styles [required]: image styles to reprocess, comma separated (ex. "mini,large,zoom")
    # - index [required]: page offset for variants querying
    # - size [required]: page size for variants querying
    # Output:
    # - array of hashes with the result status and the references for each processed image
    def perform(styles, index, batch_size)
      results = []
      styles_list = styles.split(',').map(&:to_sym)
      size = batch_size.to_i
      Spree::Variant.includes(:images).order(id: :desc).offset(index.to_i * size).limit(size).each do |variant|
        variant.images.each do |image|
          results << process_image(image, styles_list).merge(variant_id: variant.id, image_id: image.id)
        end
      end
      check_errors(results, args: [styles, index, batch_size])
      results
    end

    private

    def check_errors(results, args:)
      errors = results.reject { |result| result[:status] == :ok }
      return if errors.empty?

      ::Sentry.capture_message('UpdateVariantImagesBatchWorker errors', extra: { args: args, errors: errors })
    end

    def process_image(image, styles_list)
      image.attachment.reprocess!(*styles_list)
      { status: :ok }
    rescue StandardError => e
      { status: :error, message: e.to_s }
    end
  end
end
