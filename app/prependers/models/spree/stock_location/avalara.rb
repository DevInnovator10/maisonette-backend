# frozen_string_literal: true

module Spree::StockLocation::Avalara
  def self.prepended(base)
    base.delegate :avalara_code, to: :vendor
  end
end
