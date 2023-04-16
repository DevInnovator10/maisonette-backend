# frozen_string_literal: true

module Spree::Price::SalePrices
  def self.prepended(base)
    base.singleton_class.prepend ClassMethods
  end

  module ClassMethods
    def on_sale
      joins(:active_sale_prices)
        .where(Spree::SalePrice.arel_table[:calculated_price].lt(Spree::Price.arel_table[:amount]))
    end
  end

  private

  def first_sale(scope)
    scope.min_by(&:calculated_price)
  end
end
