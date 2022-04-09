# frozen_string_literal: true

module Spree
  module Admin
    module VendorStockLocationHelper
      def stock_location_vendor_name(stock_location)
        "(Vendor #{stock_location.vendor.name} #{stock_location_vendor_name_prefix(stock_location)})".gsub(/\s+\)/, ')')
      end

      def stock_location_vendor_name_prefix(stock_location)
        'International Vendor' if stock_location.international?
      end
    end
  end
end
