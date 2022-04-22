# frozen_string_literal: true

module Spree::Api::ApiHelpers::Subscribers
  def self.prepended(base)
    base.user_attributes.push(:subscribed)
  end
end
