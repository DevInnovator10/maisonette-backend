# frozen_string_literal: true

module Spree::StockLocation::Giftwrap
    def self.prepended(base)
    base.delegate :giftwrap_service?, to: :vendor, allow_nil: true
  end

end
