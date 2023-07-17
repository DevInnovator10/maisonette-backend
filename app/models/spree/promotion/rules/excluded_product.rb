# frozen_string_literal: true

module Spree
  class Promotion < Spree::Base
    module Rules
      class ExcludedProduct < PromotionRule
        has_many :product_promotion_rules, dependent: :destroy, foreign_key: :promotion_rule_id,
                                           class_name: 'Spree::ProductPromotionRule', inverse_of: :promotion_rule
        has_many :products, class_name: 'Spree::Product', through: :product_promotion_rules

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible?(_order, _options = {})
          true
        end

        def actionable?(line_item)
          excluded_products.exclude?(line_item.variant.product)
        end

        def product_ids_string
          product_ids.join(',')
        end

        def product_ids_string=(product_ids)
          self.product_ids = product_ids.to_s.split(',').map(&:strip)
        end

        def products_query(scope)
          scope.where.not(spree_products: { id: product_ids })
        end

        private

        def excluded_products
          products
        end
      end
    end
  end
end
