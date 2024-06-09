# frozen_string_literal: true

module Spree
  class Promotion < Spree::Base
    module Actions
      class CreateGiftCardTransaction < PromotionAction
        def perform(payload = {})
          order = payload[:order]
          gift_card = payload[:promotion_code].gift_card

          return false if gift_card.nil? || !gift_card.active?
          return false if !gift_card.redeemable?

          amount = gift_card.compute_amount(order)

          create_adjustment(order, amount, promotion, payload)
        end

        def remove_from(order)
          order.adjustments.where(source_type: 'Spree::GiftCard').find_each do |adjustment|
            if adjustment.source.value == order.coupon_code
              order.adjustments.destroy(adjustment)
            end
          end
        end

        private

        def create_adjustment(order, amount, promotion, payload)
          adjustment = Spree::Adjustment.find_or_initialize_by(
            order: order,
            adjustable: order,
            source: payload[:promotion_code].gift_card,
            promotion_code: payload[:promotion_code],
            label: I18n.t('spree.adjustment_labels.order',
                          promotion: Spree::Promotion.model_name.human,
                          promotion_name: promotion.name)
          ).tap { |a| a.amount = amount }

          adjustment.save!
        end

      end
    end
  end
end
