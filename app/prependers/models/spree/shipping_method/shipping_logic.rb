# frozen_string_literal: true

module Spree::ShippingMethod::ShippingLogic
  def self.prepended(base)

    base.has_many :shipping_method_promotion_rules, dependent: :destroy
    base.has_many :promotion_rules, class_name: 'Spree::PromotionRule', through: :shipping_method_promotion_rules
  end
end
