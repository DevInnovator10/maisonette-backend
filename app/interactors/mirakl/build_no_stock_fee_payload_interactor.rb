# frozen_string_literal: true

module Mirakl
  class BuildNoStockFeePayloadInteractor < ApplicationInteractor
    helper_methods :mirakl_order

    def call
      return if mirakl_shop.premium
      return unless no_stock_fee_conditions_met?
      return if mirakl_order.no_stock_fee == compliance_fee_amount

      mirakl_order.update(no_stock_fee: compliance_fee_amount)

      payload << { code: MIRAKL_DATA[:order][:additional_fields][:no_stock_fee],
                   value: compliance_fee_amount.round(2) }
    rescue StandardError => e
      rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
    end

    private

    def no_stock_fee_conditions_met?
      return true if order_lines.refused.present? || order_lines.no_stock_cancellation.present?

      false
    end

    def compliance_fee_amount
      @compliance_fee_amount ||= begin
                                   cancelations_total = order_lines.joins(:order_line_reimbursements).sum(:total)
                                   mirakl_order.compliance_fee_amount(affected_total: cancelations_total)
                                 end
    end

    def mirakl_shop
      mirakl_order.shipment.mirakl_shop
    end

    def order_lines
      mirakl_order.order_lines
    end

    def payload
      context.mirakl_order_additional_fields_payload ||= []
    end
  end
end
