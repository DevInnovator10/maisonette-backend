# frozen_string_literal: true

module Spree::Promotion::GiftCard
  def self.prepended(base)
    base.delegate :gift_card?, to: :promotion_category, allow_nil: true
  end

  def remove_from(order)
    actions.each do |action|
      action.remove_from(order)
    end

    return order_promotions if gift_card?

    # note: this destroys the join table entry, not the promotion itself
    order.promotions.destroy(self)
    order.order_promotions.reset
    order_promotions.reset
  end
end
