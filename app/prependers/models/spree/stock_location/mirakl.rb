# frozen_string_literal: true

module Spree::StockLocation::Mirakl
  def self.prepended(base)
    base.has_one :mirakl_shop, through: :vendor
  end

  def restock_inventory
    false
  end

  def restock_inventory?
    false
  end
end
