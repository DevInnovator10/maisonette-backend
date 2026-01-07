# frozen_string_literal: true

module Spree::PromotionHandler::Coupon::SimulateCouponCode
  def self.prepended(base)
    base.attr_reader :simulate, :promotion_adjustments
  end

  def simulate_coupon_code(coupon_code)
    db_connection.transaction do
      @simulate = true

      @coupon_code = order.coupon_code = coupon_code.downcase

      apply

      promotion_adjustments

      raise ActiveRecord::Rollback
    end

    promotion_adjustments
  end

  private

  def db_connection
    ActiveRecord::Base.connection
  end

  def promotion_adjustments
    @promotion_adjustments ||= order.all_adjustments
                                    .select(&:promotion?)
                                    .select { |a| a.promotion_code&.value == coupon_code }
                                    .map(&:dup)
  end
end
