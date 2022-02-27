# frozen_string_literal: true

module Syndication
  class Product < Syndication::Base
    include Concerns::AlgoliaProductIndex

    before_validation :assign_algolia_attributes_updated_at, unless: :is_product

    private

    def assign_algolia_attributes_updated_at
      return if (changed_attributes.keys & ALGOLIA_VARIANT_ATTRIBUTES.map(&:to_s)).blank?

      self.algolia_attributes_updated_at = Time.current
    end
  end
end
