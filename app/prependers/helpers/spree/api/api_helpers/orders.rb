# frozen_string_literal: true

module Spree::Api::ApiHelpers::Orders
  def self.prepended(base)
    base.order_attributes.push :gift_email, :gift_message, :is_gift, :use_store_credits, :first_order
  end
end
