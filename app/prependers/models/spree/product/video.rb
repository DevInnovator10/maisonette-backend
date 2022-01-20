# frozen_string_literal: true

module Spree::Product::Video
  def self.prepended(base)
    base.delegate :videos, to: :find_or_build_master
  end
end
