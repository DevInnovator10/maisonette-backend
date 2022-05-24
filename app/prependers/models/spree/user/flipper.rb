# frozen_string_literal: true

module Spree::User::Flipper
  def self.prepended(base)
    base.include Maisonette::Flipper::Identifier
  end
end
