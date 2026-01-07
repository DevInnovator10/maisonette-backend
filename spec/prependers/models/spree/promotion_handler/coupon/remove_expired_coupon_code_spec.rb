# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::PromotionHandler::Coupon::RemoveExpiredCouponCode, type: :model do
  let(:described_class) { Spree::PromotionHandler::Coupon }

  let(:coupon_handler) { described_class.new(order) }
  let(:order) { create(:order, state: 'delivery').tap { |o| o.coupon_code = promotion_code.value } }
  let(:promotion) { create(:promotion, :with_order_adjustment) }
  let(:promotion_code) { create(:promotion_code, promotion: promotion) }

  describe '#remove' do
    context 'with an already applied expired coupon' do
      before do
        described_class.new(order).apply
        order.reload

        promotion.update!(expires_at: Time.zone.now - 1.day)
      end

      it 'successfully removes the coupon code from the order' do
        coupon_handler.remove
        expect(coupon_handler).to be_successful
      end
    end
  end

end
