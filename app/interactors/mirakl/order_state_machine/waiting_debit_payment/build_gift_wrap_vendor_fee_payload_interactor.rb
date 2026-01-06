# frozen_string_literal: true

module Mirakl
  module OrderStateMachine
    module WaitingDebitPayment
      class BuildGiftWrapVendorFeePayloadInteractor < ApplicationInteractor
        helper_methods :mirakl_order

        def call
          return unless shipment.has_giftwrap?

          payload << { code: MIRAKL_DATA[:order][:additional_fields][:gift_wrap_vendor_fee],
                       value: shipment.mirakl_shop.gift_wrap_fee.to_f }
        rescue StandardError => e
          rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        end

        private

        def shipment
          mirakl_order.shipment
        end

        def payload
          context.mirakl_order_additional_fields_payload ||= []
        end
      end
    end
  end
end
