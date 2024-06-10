# frozen_string_literal: true

module Spree::Address::StateValidation
  def self.prepended(base)
    base.attr_accessor :skip_state_validation

  end
end
