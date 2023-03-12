# frozen_string_literal: true

module Mirakl
  class UpdateOfferDiscountPricesWorker
    include Sidekiq::Worker

    sidekiq_options lock: :while_executing

    OFFER_DISCOUNT_CSV_HEADERS = %w[sku shop-id product-id product-id-type state discount-start-date
                                    discount-end-date discount-price].freeze

    def perform(product_ids)
      @offers_csv = generate_csv_with_headers
      generate_csv_rows(product_ids)
      offer_export = create_offer_export_job
      offer_export.send_offers_to_mirakl
    end

    private

    def offers_to_update(product_ids)
      Mirakl::Offer.joins(spree_price: [variant: :product])
                   .where(spree_products: { id: product_ids })
                   .distinct
                   .find_each
                   .reject { |offer| offer.price == offer.spree_price.price }
    end

    def offer_discount(sale_price)
      return unless sale_price

      { price: sale_price.calculated_price,
        start_date: sale_price.start_at,
        end_date: sale_price.end_at }
    end

    def create_offer_export_job
      Salsify::MiraklOfferExportJob.create.tap do |offer_export_job|
        offer_export_job.offers.attach(
          io: StringIO.new(@offers_csv),
          filename: 'solidus_onsale_offers.csv',
          content_type: 'text/csv'
        )
      end
    end

    def generate_csv_with_headers
      CSV.generate_line(OFFER_DISCOUNT_CSV_HEADERS, col_sep: ',')
    end

    def offer_line_row(offer)
      offer_row_hash(offer)
    rescue StandardError => e
      message = "Unable to update mirakl discount price for offer sku - #{offer.sku}"
      Sentry.capture_exception_with_message(e, message: message)
    end

    def offer_row_hash(offer)
      {
        'sku': offer.spree_price.offer_settings.vendor_sku,
        'shop-id': offer.shop.shop_id,
        'product-id': offer.sku,
        'product-id-type': 'SKU',
        'state': 11,
        'discount-start-date': offer_discount(offer.spree_price.active_sale)&.dig(:start_date)&.iso8601,
        'discount-end-date': offer_discount(offer.spree_price.active_sale)&.dig(:end_date)&.iso8601,
        'discount-price': offer_discount(offer.spree_price.active_sale)&.dig(:price)
      }
    end

    def generate_csv_rows(product_ids)
      offers_to_update(product_ids).each do |offer|
        row = offer_line_row(offer)
        next if row.nil?

        @offers_csv << CSV.generate_line(row.values, col_sep: ',')
      end
    end
  end
end
