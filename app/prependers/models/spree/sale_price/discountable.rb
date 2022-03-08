# frozen_string_literal: true

module Spree::SalePrice::Discountable
  def discountable
    sale_sku_configuration || mark_down
  end
end
