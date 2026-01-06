# frozen_string_literal: true

require 'csv'

module Mirakl
  class UpdateOffersInteractor < ApplicationInteractor
    before :prepare_affected_offers_log
    after :ensure_all_offers_updated, :process_offers

    def call
      csv_file = CSV.parse(context.offers, headers: true, col_sep: ';')
      csv_file.each do |row|
        row['deleted'] == 'true' ? delete_offer!(row) : upsert_offer!(row)
        updated_skus << row['product-sku'].force_encoding('utf-8')
      rescue StandardError => e
        error_message = I18n.t('errors.update_offer_error',
                               class_name: self.class.to_s,
                               e: e.message,
                               csv_row_hash: row.to_hash)
        Sentry.capture_exception_with_message(e, message: error_message)
        context.failed_offer_update = true
      end
    end

    private

    def prepare_affected_offers_log
      context.affected_offers = { deleted_offer: [], upserted_offer: [] }
    end

    def delete_offer!(row)
      Mirakl::Offer.find_by(offer_id: row['offer-id'])&.destroy!
      context.affected_offers[:deleted_offer] << row['offer-id']
    end

    def upsert_offer!(row)
      mirakl_offer(row).update!(shop_id: Mirakl::Shop.find_by(shop_id: row['shop-id']).id,
                                active: active_offer?(row),
                                offer_state: row['state-code'],
                                sku: row['product-sku'],
                                shop_sku: row['shop-sku'],
                                quantity: row['quantity'],
                                original_price: row['origin-price'],
                                price: row['price'],
                                available_from: row['available-start-date'],
                                available_to: row['available-end-date'])
      context.affected_offers[:upserted_offer] << row['offer-id']
    end

    def mirakl_offer(row)
      Mirakl::Offer.find_or_initialize_by(offer_id: row['offer-id'])
    end

    def active_offer?(row)
      row['active'] == 'true'
    end

    def updated_skus
      @updated_skus ||= []
    end

    def process_offers
      updated_skus.uniq.each_slice(10) do |skus|
        Mirakl::ProcessOffersWorker.perform_async(skus)
      end
    end

    def ensure_all_offers_updated
      context.fail!(error: 'an offer did not update') if context.failed_offer_update
    end
  end
end
