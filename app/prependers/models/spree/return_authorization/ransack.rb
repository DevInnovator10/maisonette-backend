# frozen_string_literal: true

module Spree::ReturnAuthorization::Ransack
  def self.prepended(base)
    base.whitelisted_ransackable_associations = ['order']
    base.whitelisted_ransackable_attributes.push('number', 'state')
  end
end
