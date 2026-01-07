# frozen_string_literal: true

module Spree::Api::ApiHelpers::Marketplace
  def self.prepended(base)
    base.line_item_attributes.push(:vendor_id)
  end
end
