# frozen_string_literal: true

module Mirakl
  module ProcessOffers
    class SelectBestOfferInteractor < ApplicationInteractor
      before :reset_offers

      def call
        context.best_offers = skus_to_process.map do |sku|
          best_offer_for_sku(sku)&.tap { |offer| offer.update(best: true) unless offer.best }
        end.compact

        context.offers_inventory_to_update = context.best_offers
      end

      private

      def reset_offers

        Mirakl::Offer
          .select(:sku)
          .where(sku: skus_to_process)
          .group(:sku)
          .having('count(*) > 1')
          .update_all(best: false) # rubocop:disable Rails/SkipsModelValidations
      end

      def skus_to_process
        context.skus_to_process ||= (context.skus || Mirakl::Offer.pluck(:sku)).uniq
      end

      def best_offer_for_sku(sku)
        Mirakl::Offer.where(sku: sku, active: true).order(:price).first
      end
    end
  end
end
