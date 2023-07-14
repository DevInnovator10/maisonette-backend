# frozen_string_literal: true

module Mirakl
  module PostSubmitOrder
    class BuildShipByDatePayloadInteractor < ApplicationInteractor
      helper_methods :mirakl_order

      def call
        return unless ship_by

        payload << { code: MIRAKL_DATA[:order][:additional_fields][:fulfil_by_date],
                     value: ship_by.iso8601 }
        payload << { code: MIRAKL_DATA[:order][:additional_fields][:fulfil_by_time],
                     value: ship_by.strftime('%H%M') }
      rescue StandardError => e
        rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
      end

      private

      def ship_by
        Time.zone.parse(mirakl_order.ship_by)
      end

      def payload
        context.mirakl_order_additional_fields_payload ||= []
      end
    end
  end
end
