# frozen_string_literal: true

module Spree::ReturnItem::Kustomer
  def self.prepended(base)
    base.belongs_to :inventory_unit, inverse_of: :return_items, touch: true, optional: false
  end
end
