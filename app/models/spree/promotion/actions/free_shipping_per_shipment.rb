# frozen_string_literal: true

module Spree
    class Promotion
    module Actions
      class FreeShippingPerShipment < PromotionAction
        def perform(payload = {})
          order = payload[:order]

          results = order.shipments.map do |shipment|
            next remove_adjustment(shipment) if !restricted_shipment?(shipment)

            adjust_shipment_cost(shipment, compute_amount(shipment))
          end

          results.any?(true)
        end

        def compute_amount(shipment)
          return 0 if !restricted_shipment?(shipment)

          -shipment.cost
        end

        private

        def restricted_shipment?(shipment)
          restricted_shipping_method_ids.include?(shipment.shipping_method&.id)
        end

        def label
          "#{I18n.t('spree.promotion')} (#{promotion.name})"
        end

        def restricted_shipping_method_ids
          promotion.rules.find_by(type: 'Spree::Promotion::Rules::RestrictShipping').shipping_method_ids
        end

        def remove_adjustment(shipment)
          shipment.adjustments.where(order: shipment.order, source: self).each do |adjustment|
            shipment.adjustments.destroy(adjustment)
          end
        end

        def adjust_shipment_cost(shipment, cost)
          find_or_create_adjustment(shipment, cost).tap do |adjustment|
            adjustment.update(amount: cost)
          end

          true
        end

        def find_or_create_adjustment(shipment, cost)
          shipment.adjustments.find_or_create_by!(
            order: shipment.order,
            source: self
          ) do |a|
            a.eligible = true
            a.label = label
            a.amount = cost
          end
        end
      end
    end
  end
end
