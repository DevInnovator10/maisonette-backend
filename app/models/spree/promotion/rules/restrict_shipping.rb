# frozen_string_literal: true

module Spree
  class Promotion
    module Rules
      class RestrictShipping < PromotionRule
        has_many :shipping_method_promotion_rules,
                 dependent: :destroy,
                 foreign_key: :promotion_rule_id,
                 class_name: 'Spree::ShippingMethodPromotionRule',
                 inverse_of: :promotion_rule
        has_many :shipping_methods, class_name: 'Spree::ShippingMethod', through: :shipping_method_promotion_rules

        preference :name, :string, default: ''

        def applicable?(promotable)
          promotable.is_a?(Spree::Order) || promotable.is_a?(Spree::Shipment)
        end

        def eligible?(promotable, _options = {})
          promotable = promotable.order if promotable.is_a?(Spree::Shipment)

          promotable.shipments.flat_map do |shipment|
            shipment.shipping_method&.id
          end.any? { |id| shipping_method_ids.include? id }
        end
      end
    end
  end
end
