# frozen_string_literal: true

module Spree::Variant::Ransack
  def self.prepended(base)
    base.whitelisted_ransackable_attributes ||= []
    base.whitelisted_ransackable_attributes.push('is_master')
  end
end
