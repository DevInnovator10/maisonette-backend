# frozen_string_literal: true

module Spree::LineItem::Giftwrap
  def self.prepended(base)
    base.has_many :shipments, through: :inventory_units
  end
end
