# frozen_string_literal: true

module Mirakl
    module ProcessOffers
    class SetPriceInteractor < ApplicationInteractor
      attr_reader :offer

      def call
        context.updated_price_skus = []

        offers_to_process.find_each do |offer|
          log_event(:info, "updating price sku: #{offer.sku}")
          context.updated_price_skus << offer.sku if apply_offer(offer)
        end
      end

      private

      def offers_to_process
        Mirakl::Offer.where(sku: context.skus_to_process, active: true)
      end

      def fetch_offer_settings(offer)
        Spree::OfferSettings.find_by(maisonette_sku: offer.sku)
      end

      def apply_offer(offer) # rubocop:disable Metrics/MethodLength
        ActiveRecord::Base.transaction do
          offer_settings = fetch_offer_settings(offer)
          return missing_offer_settings(offer) unless offer_settings

          price = find_or_create_price(offer, offer_settings)

          price.update!(deleted_at: nil, amount: offer.original_price)
          Spree::UpdatePermanentSalePriceInteractor.call(offer_settings: offer_settings)
          true
        end
      rescue StandardError => e
        error_message = I18n.t('errors.update_price_error',
                               e: e.message,
                               offer_id: offer.id)
        Sentry.capture_exception_with_message(e, message: error_message)
        false
      end

      def find_or_create_price(offer, offer_settings)
        variant = offer_settings.variant
        variant.update!(available_until: nil) if variant.discontinued?

        price_for_offer(offer, variant, offer_settings)
      end

      def price_for_offer(offer, variant, offer_settings)
        variant.prices
               .with_discarded
               .find_or_initialize_by(mirakl_offer: offer, vendor: offer.vendor, offer_settings: offer_settings)
      end

      def missing_offer_settings(offer)
        log_event(:warn, "OfferSettings missing for sku: #{offer.sku}")
      end
    end
  end
end
