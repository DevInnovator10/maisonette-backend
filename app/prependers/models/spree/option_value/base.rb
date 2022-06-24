# frozen_string_literal: true

module Spree::OptionValue::Base
  def self.prepended(base)
    base.has_many :maisonette_variant_group_attributes, class_name: 'Maisonette::VariantGroupAttributes'

    base.has_many :products, through: :maisonette_variant_group_attributes
  end
end
