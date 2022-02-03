# frozen_string_literal: true

module Spree::ShippingCategory::ShippingLogic
  def self.prepended(base)
    base.has_many :variants
    base.has_many :products, through: :variants
  end
end
