# frozen_string_literal: true

module Spree::PromotionHandler::Coupon::GiftCard
    private

  def handle_present_promotion(promotion)
    return promotion_usage_limit_exceeded if promotion.usage_limit_exceeded? || promotion_code.usage_limit_exceeded?
    return promotion_applied if promotion_exists_on_order?(order, promotion) && !promotion.gift_card?

    unless promotion.eligible?(order, promotion_code: promotion_code)
      set_promotion_eligibility_error_code(promotion)
      return (error || ineligible_for_this_order)
    end

    activate_promotion(promotion)
  end

  def activate_promotion(promotion)
    # If any of the actions for the promotion return `true`,
    # then result here will also be `true`.
    result = promotion.activate(order: order, promotion_code: promotion_code)
    if result
      order.recalculate
      set_success_code :coupon_code_applied
    else
      set_error_code :coupon_code_unknown_error
    end
  end
end
