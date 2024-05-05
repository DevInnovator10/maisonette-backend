# frozen_string_literal: true

module Spree::Carton::Base
  def self.prepended(base)

    base.has_many :line_items, through: :inventory_units
  end

  def display_shipped_at
    shipped_at&.to_s(:rfc822) || ''
  end

  def line_item_for(variant, order)
    line_items.find_by(variant: variant, order: order)
  end
end
