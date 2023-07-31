# frozen_string_literal: true

module Spree
    class Promotion
    module Actions
      class DetractOtherShippingCost < PromotionAction
        preference :shipping_method_id, :integer

        def perform(payload = {})
          @order = payload[:order]
          @expedited_shipments = nil

          results = @order.shipments.map do |shipment|
            next remove_adjustment(shipment) unless restricted_shipment?(shipment)

            amount = compute_amount(shipment)
            adjust_shipment_cost(shipment, amount)
            true
          end

          results.any? { |r| r == true }
        end

        def compute_amount(shipment)
          @order = shipment.order

          amount = if expedited_shipments.first == shipment
                     if not_free_grouped_shipments.any?
                       shipment.selected_shipping_rate.shipping_method.base_flat_rate_amount.to_f
                     else
                       0.0
                     end
                   else
                     shipment.selected_shipping_rate.shipping_method.base_flat_rate_amount.to_f
                   end
          -amount
        end

        private

        def expedited_shipments
          @expedited_shipments ||= @order.shipments.select { |shipment| restricted_shipment?(shipment) }
        end

        def not_free_grouped_shipments
          (@order.shipments - expedited_shipments).select do |shipment|
            Spree::Promotion::Actions::GroupShipping.first.restricted_shipment?(shipment) && !shipment.total.zero?
          end
        end

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

        def adjust_shipment_cost(shipment, amount)
          find_or_create_adjustment(shipment, amount).tap do |adjustment|
            adjustment.update(amount: amount)
          end
        end

        def find_or_create_adjustment(shipment, amount)
          shipment.adjustments.find_or_create_by!(order: shipment.order, source: self) do |adjustment|
            adjustment.eligible = true
            adjustment.label = label
            adjustment.amount = amount
          end
        end
      end
    end
  end
end
