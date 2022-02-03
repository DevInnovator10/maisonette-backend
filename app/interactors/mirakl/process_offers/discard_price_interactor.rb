# frozen_string_literal: true

module Mirakl
  module ProcessOffers
    class DiscardPriceInteractor < ApplicationInteractor
      attr_reader :offer

      def call
        context.discarded_price_skus = []

        offers_to_process.find_each do |offer|
          log_event(:warn, "Discarding offer price: #{offer.sku}")
          context.discarded_price_skus << offer.sku if discard_price(offer)
        end
      end

      private

      def offers_to_process
        Mirakl::Offer.where(sku: context.skus_to_process, active: false)
      end

      def discard_price(offer)
        offer&.spree_price&.discard
      rescue StandardError => e
        error_message = I18n.t('errors.update_price_error',
                               e: e.message,
                               offer_id: offer.id)
        Sentry.capture_exception_with_message(e, message: error_message)
        false
      end
    end
  end
end
