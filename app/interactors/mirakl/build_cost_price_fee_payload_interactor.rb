# frozen_string_literal: true

module Mirakl
  class BuildCostPriceFeePayloadInteractor < ApplicationInteractor
    before :adjust_for_reimbursements

    def call
      return if mirakl_order.invoiced?
      return unless mirakl_order.order_lines.has_cost_price_total.any?

      payload << { code: MIRAKL_DATA[:order][:additional_fields][:cost_price_fee],
                   value: cost_price_fee_total }
    rescue StandardError => e
      rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
    end

    private

    def mirakl_order
      context.mirakl_order
    end

    def cost_price_fee_total
      @cost_price_fee_total ||= mirakl_order.order_lines.sum(:cost_price_fee_total)
    end

    def order_lines_with_cost_price_and_reimbursements
      @order_lines_with_cost_price_and_reimbursements ||= begin
        mirakl_order.order_lines.has_cost_price_total.with_order_line_reimbursements
      end
    end

    def cancelled_cost_price_credit(order_line)
      order_line.cost_price_fee_amount * order_line.quantity
    end

    def refund_and_rejection_cost_price_credit(order_line)
      order_line.order_line_reimbursements.refunds_or_rejections.sum(:quantity) * order_line.cost_price_fee_amount
    end

    def adjust_for_reimbursements
      order_lines_with_cost_price_and_reimbursements.each do |order_line|
        cost_price_fee_total =
          cancelled_cost_price_credit(order_line) - refund_and_rejection_cost_price_credit(order_line)

        order_line.update(cost_price_fee_total: cost_price_fee_total)
      end
    end

    def payload
      context.mirakl_order_additional_fields_payload ||= []
    end
  end
end
