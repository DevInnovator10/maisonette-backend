# frozen_string_literal: true

module Spree
  class ShippingCarrier < ApplicationRecord
    validates :name, :code, :easypost_carrier_id, presence: true

    has_many :shipping_method_carriers, inverse_of: :shipping_carrier, dependent: :destroy
    has_many :shipping_methods, through: :shipping_method_carriers
  end
end
