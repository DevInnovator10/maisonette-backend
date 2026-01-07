# frozen_string_literal: true

module Spree
  class Promotion
    module Actions
      class GroupShipping < PromotionAction
        def perform(payload = {})
          @order = payload[:order]

          results = @order.shipments.map do |shipment|
            next remove_adjustment(shipment) if most_expensive_shipment?(shipment) || !restricted_shipment?(shipment)

            adjust_shipment_cost(shipment, compute_amount(shipment))
          end

          results.any?(true)
        end

        def compute_amount(shipment)
          @order = shipment.order

          return 0 if most_expensive_shipment?(shipment)

          -shipment.cost
        end

        def restricted_shipment?(shipment)
          restricted_to_shipping_method_ids.include?(shipment.shipping_method&.id)
        end

        private

        def most_expensive_shipment?(shipment)
          shipment.id == most_expensive_shipment_id
        end

        def label
          "#{I18n.t('spree.promotion')} (#{promotion.name})"
        end

        def restricted_to_shipping_method_ids
          promotion.rules.find_by(type: 'Spree::Promotion::Rules::RestrictShipping').shipping_method_ids
        end

        def most_expensive_shipment_id
          @most_expensive_shipment_id ||= Spree::ShippingRate
                                          .joins(:shipment)
                                          .where(
                                            spree_shipments: {
                                              order_id: @order.id
                                            },
                                            shipping_method_id: restricted_to_shipping_method_ids,
                                            selected: true
                                          )
                                          .order(cost: :desc)
                                          .pluck(:shipment_id)
                                          .first
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
