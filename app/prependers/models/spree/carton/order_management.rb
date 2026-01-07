# frozen_string_literal: true

module Spree::Carton::OrderManagement
  def self.prepended(base)
    base.class_eval do
      _validators.reject! { |key, _| key == :shipped_at }

      _validate_callbacks.each do |callback|
        if callback.raw_filter.respond_to? :attributes
          callback.raw_filter.attributes.delete :shipped_at
        end
      end
    end
  end
end
