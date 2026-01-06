# frozen_string_literal: true

module Spree::CustomerReturn::Ransack
    def self.prepended(base)
    base.whitelisted_ransackable_associations = ['stock_location']
    base.whitelisted_ransackable_attributes ||= []
    base.whitelisted_ransackable_attributes.push('number')
  end
end
