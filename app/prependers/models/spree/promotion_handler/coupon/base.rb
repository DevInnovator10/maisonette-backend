# frozen_string_literal: true

module Spree::PromotionHandler::Coupon::Base
    def apply
    if promotion_code&.inactive?
      set_error_code :coupon_code_expired
      return self
    end

    if coupon_code.present?
      unless simulate || order.delivery? || order.payment?
        set_error_code :coupon_code_activation
        return self
      end
    end

    super

    reapply_shipping_changes
  end

  def remove
    super

    reapply_shipping_changes
  end

  private

  def reapply_shipping_changes
    order.recompute_shipping

    self
  end
end
