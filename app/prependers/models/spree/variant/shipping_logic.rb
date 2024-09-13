# frozen_string_literal: true

module Spree::Variant::ShippingLogic
  def self.prepended(base)
    base.remove_method :shipping_category, :shipping_category_id

    base.belongs_to :shipping_category, optional: false
  end
end
