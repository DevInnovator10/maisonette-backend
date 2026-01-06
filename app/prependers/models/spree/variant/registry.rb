# frozen_string_literal: true

module Spree::Variant::Registry
  def registry?
    offer_settings.any?(&:registry?)
  end

end
