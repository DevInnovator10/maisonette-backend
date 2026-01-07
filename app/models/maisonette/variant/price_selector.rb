# frozen_string_literal: true

module Maisonette
  module Variant
    class PriceSelector < Spree::Variant::PriceSelector
      def self.pricing_options_class
        Maisonette::Variant::PricingOptions
      end

      def price_for(price_options, as_money: true)
        selected_price = prices_by_options(price_options).min_by(&:price)

        return selected_price&.money if as_money

        selected_price
      end

      def price_for_vendor(vendor, opts = {})
        vendor_id = vendor.is_a?(Spree::Vendor) ? vendor.id : vendor
        price_options = Spree::Config.pricing_options_class.new(vendor_id: vendor_id)

        price_for(price_options, opts)
      end

      private

      def prices_by_options(options)
        variant.currently_valid_prices.select do |price|
          price.currency == options.desired_attributes[:currency] &&
            (price.country_iso == options.desired_attributes[:country_iso] || price.country_iso.nil?) &&
            (price.vendor_id == options.desired_attributes[:vendor_id] || options.desired_attributes[:vendor_id].nil?)
        end
      end
    end
  end
end
