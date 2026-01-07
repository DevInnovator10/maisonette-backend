# frozen_string_literal: true

module Maisonette
  class VariantGroupAttributes < ApplicationRecord
    belongs_to :option_value, class_name: 'Spree::OptionValue', optional: false
    belongs_to :product, class_name: 'Spree::Product', optional: false

    has_many :option_values_variants, class_name: 'Spree::OptionValuesVariant', through: :option_value
    has_many :variants, class_name: 'Spree::Variant', through: :option_values_variants
    has_many :line_items, class_name: 'Spree::LineItem', through: :variants
    has_many :orders, class_name: 'Spree::Order', through: :line_items

    has_many :images, class_name: 'Spree::Image', inverse_of: :maisonette_variant_group_attributes,
                      foreign_key: 'maisonette_variant_group_attributes_id', dependent: :nullify
    has_many :product_properties, class_name: 'Spree::ProductProperty',
                                  inverse_of: :maisonette_variant_group_attributes,
                                  foreign_key: 'maisonette_variant_group_attributes_id', dependent: :nullify

    validates :sku, uniqueness: { allow_blank: true }

    scope :suppliable, -> { where(product_id: Spree::Variant.suppliable.select(:product_id)) }
    scope :with_prices_on_non_master_variants,
          lambda {
            where(product_id: Spree::Variant.with_prices.not_master.select(:product_id))
          }
    scope :with_option_values_on_non_master_variants,
          lambda {
            where(product_id: Spree::Variant.with_option_values_on_non_master_variants.select(:product_id))
          }
    scope :purchasable, lambda {
                          available
                            .with_prices_on_non_master_variants
                            .with_option_values_on_non_master_variants
                            .suppliable
                        }

    def self.available(available_at = nil)
      available_at ||= Time.current
      available_on_table = Maisonette::VariantGroupAttributes.arel_table[:available_on]
      available_until_table = Maisonette::VariantGroupAttributes.arel_table[:available_until]

      where(available_on_table.lteq(available_at))
        .where(available_until_table.eq(nil)
                                    .or(available_until_table.gteq(available_at)))
    end

    def total_on_hand
      variants.sum(&:total_on_hand)
    end
  end

end
