# frozen_string_literal: true

module Spree::Api::ApiHelpers::Promotions
  def self.prepended(base)
    base.promotion_attributes.push :advertised_text, :advertised_text_short
  end
end
