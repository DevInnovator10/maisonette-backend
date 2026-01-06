# frozen_string_literal: true

module Spree::Product::RansackableScopes
  def self.prepended(base)
    base.singleton_class.prepend ClassMethods
  end

  module ClassMethods
    def ransackable_scopes(auth_object = nil)
      super(auth_object) + %i[out_of_stock in_stock]
    end
  end
end
