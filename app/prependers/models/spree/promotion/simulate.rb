# frozen_string_literal: true

module Spree::Promotion::Simulate
  def self.prepended(base)
    base.singleton_class.prepend ClassMethods
  end

  module ClassMethods
    def order_activatable?(_order)
      true
    end
  end
end
