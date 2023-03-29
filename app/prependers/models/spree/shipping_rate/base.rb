# frozen_string_literal: true

module Spree::ShippingRate::Base
  FLAT_RATE_RULE_NAME = 'flat_rate'
  FREE_SHIPPING_RULE_NAME = 'free_shipping'
  FLAT_RATE_EXPEDITED_RULE_NAME = 'flat_rate_expedited'

  delegate :admin_name, :base_flat_rate_amount, to: :shipping_method

  def flat_rate?
    shipping_method.promotion_rules.where(preferences: { name: FLAT_RATE_RULE_NAME }).exists?
  end

  def flat_rate_expedited?
    shipping_method.promotion_rules.where(preferences: { name: FLAT_RATE_EXPEDITED_RULE_NAME }).exists?
  end

  def free_shipping?
    restrict_rule = shipping_method.promotion_rules.find_by(type: 'Spree::Promotion::Rules::RestrictShipping')
    restrict_rule.present? ? restrict_order_free_shipping? : item_order_free_shipping?
  end

  def item_order_free_shipping?
    shipping_method.promotion_rules.where(preferences: { name: FREE_SHIPPING_RULE_NAME }).exists? &&
      shipping_method.promotion_rules.where(type: 'Spree::Promotion::Rules::ItemTotal').exists? &&
      Maisonette::Config.free_shipping_threshold &&
      order.item_total > Maisonette::Config.free_shipping_threshold
  end

  def restrict_order_free_shipping?
    rule = shipping_method.promotion_rules.find_by(type: 'Spree::Promotion::Rules::RestrictShipping')
    rule_item_total = rule.promotion.promotion_rules.find_by(type: 'Spree::Promotion::Rules::RestrictShippingItemTotal')
    rule_item_total.present? ? rule_item_total.eligible?(order, {}) : item_order_free_shipping?
  end

  def extra_cost
    cost_mapping
  end

  def total_cost
    cost_mapping(true)
  end

  def cost_mapping(total_cost = false)
    if free_shipping?
      'Free'
    elsif flat_rate?
      '(Included in flat rate)'
    elsif flat_rate_expedited?
      cost = shipping_method.expedited_flat_rate_adjustment
      cost = (base_flat_rate_amount.to_f + shipping_method.expedited_flat_rate_adjustment) if total_cost

      "+#{Spree::Money.new(cost)}"
    else
      "+#{display_cost}"
    end
  end
end
