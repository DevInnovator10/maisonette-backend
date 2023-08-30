# frozen_string_literal: true

module Mirakl
  module OrderStateMachine
    module Shipped
      class BuildLateShippingFeePayloadInteractor < ApplicationInteractor
        helper_methods :mirakl_order

        def call
          return if mirakl_order.fetch_additional_field(late_shipping_fee_label)
          return unless late_shipping_fee_criteria?

          compliance_fee_amount = mirakl_order.compliance_fee_amount
          mirakl_order.update(late_shipping_fee: compliance_fee_amount)

          payload << { code: late_shipping_fee_label,
                       value: compliance_fee_amount.round(2) }
        rescue StandardError => e
          rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        end

        private

        def mirakl_shop
          mirakl_order.shipment.mirakl_shop
        end

        def late_shipping_fee_criteria?
          return false if mirakl_shop.premium
          return false if mirakl_order.shipped_date <= mirakl_order.ship_by

          true
        end

        def payload
          context.mirakl_order_additional_fields_payload ||= []
        end

        def late_shipping_fee_label
          MIRAKL_DATA[:order][:additional_fields][:late_shipping_fee]
        end
      end
    end
  end
end
