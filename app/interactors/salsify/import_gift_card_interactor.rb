# frozen_string_literal: true

module Salsify
  class ImportGiftCardInteractor < ApplicationInteractor
    GIFT_CARD_TYPE = 'E-Gift Cards'

    def call
      return unless product_is_gift_card?

      update_product
      update_stock
      update_price
    end

    private

    def product_is_gift_card?
      context.row['Type'] == GIFT_CARD_TYPE
    end

    def update_product
      product.assign_attributes(gift_card: true, promotionable: false, available_on: nil)
      product.save! if product.changed?
    end

    def update_stock
      stock_location = vendor.stock_location
      stock_item = variant.stock_items.find_or_initialize_by(stock_location: stock_location)
      stock_item.backorderable = false
      stock_item.set_count_on_hand(0)
    end

    def update_price
      price = variant.prices.find_or_initialize_by(vendor: vendor)
      price.update!(amount: context.row['Maisonette Retail'])
    end

    def product
      context.product
    end

    def variant
      context.variant
    end

    def vendor
      context.vendor
    end
  end
end
