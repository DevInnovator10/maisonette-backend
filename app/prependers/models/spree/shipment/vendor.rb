# frozen_string_literal: true

module Spree::Shipment::Vendor
  def self.prepended(base)
    base.delegate :vendor, to: :stock_location
  end
end
