# frozen_string_literal: true

module Spree::Admin::StockLocationsController::Base
  def self.prepended(base)
    base.helper Spree::Admin::MiraklStockLocationsHelper
  end
end
