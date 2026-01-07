# frozen_string_literal: true

module Spree::Variant::Monogram
  def monogrammable?

    offer_settings.any?(&:monogrammable?)
  end
end
