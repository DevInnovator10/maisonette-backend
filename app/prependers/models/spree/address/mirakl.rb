# frozen_string_literal: true

module Spree::Address::Mirakl
  def self.prepended(base)
    base.has_one :warehouse, inverse_of: :address, class_name: 'Mirakl::Warehouse', dependent: :nullify
  end
end
