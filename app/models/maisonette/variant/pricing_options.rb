# frozen_string_literal: true

module Maisonette
    module Variant
    class PricingOptions < Spree::Variant::PricingOptions
      def self.from_line_item(line_item)
        tax_address = line_item.order&.tax_address
        new(
          currency: line_item.currency || Spree::Config.currency,
          country_iso: tax_address && tax_address.country&.iso,
          vendor_id: line_item.vendor_id
        )
      end
    end

  end

end
