# frozen_string_literal: true

module Spree::Stock::Quantifier::EnsureAvailability
    def can_supply?(required)
    return false unless @variant.available?

    super
  end
end
