# frozen_string_literal: true

module OrderManagement
    class ReturnEligibleItemsInteractor < ApplicationInteractor
    before :validate_context

    def call
      context.items = promotion_adjustments.inject([]) do |line_items_accumulator, adjustment|
        line_items_accumulator |= process_line_item_adjustment(adjustment)
        line_items_accumulator |= process_shipment_adjustment(adjustment)
        line_items_accumulator | process_order_adjustment(adjustment)
      end
    end

    private

    def process_line_item_adjustment(adjustment)
      return [] unless adjustment.adjustable_type == 'Spree::LineItem'

      [
        {
          type: 'Spree::LineItem',
          id: adjustment.adjustable.id,
          order_item_summary_ref: adjustment.adjustable.order_item_summary.order_management_ref
        }
      ]
    end

    def process_shipment_adjustment(adjustment)
      return [] unless adjustment.adjustable_type == 'Spree::Shipment'

      [{ type: 'Spree::Shipment', id: adjustment.adjustable.id }]
    end

    def process_order_adjustment(adjustment)
      return [] unless adjustment.adjustable_type == 'Spree::Order'

      adjustment.order.line_items.map do |li|
        { type: 'Spree::LineItem', id: li.id, order_item_summary_ref: li.order_item_summary.order_management_ref }
      end
    end

    def promotion_adjustments
      Spree::PromotionHandler::Coupon.new(context.order).simulate_coupon_code(context.coupon_code)
    end

    def validate_context
      context.fail!(message: 'Missing Order') if context.order.nil?
      context.fail!(message: 'Missing Coupon code') if context.coupon_code.nil?
    end
  end
end
