# frozen_string_literal: true

module Spree::DefaultPrice::Marketplace
  def self.prepended(base)
    base.module_eval do
      def find_or_build_default_price
        default_price || Spree::NullPrice.new
      end

      def default_price
        currently_valid_prices.with_default_attributes.first
      end
    end
  end
end
