# frozen_string_literal: true

module Spree::ProductProperty::Base
  def self.prepended(base)
    base.belongs_to :maisonette_variant_group_attributes, optional: true,
                                                          class_name: 'Maisonette::VariantGroupAttributes'
  end
end
