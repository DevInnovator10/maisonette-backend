# frozen_string_literal: true

module Spree::Product::OfferSettings
  def self.prepended(base)
    base.has_many :vendors, through: :variants

    base.has_many :offer_settings, through: :variants
  end
end
