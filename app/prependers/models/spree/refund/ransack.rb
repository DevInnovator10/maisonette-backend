# frozen_string_literal: true

module Spree::Refund::Ransack
  def self.prepended(base)
    base.whitelisted_ransackable_attributes ||= []
    base.whitelisted_ransackable_attributes.push('amount', 'transaction_id')
  end

end
