# frozen_string_literal: true

module Mirakl
  class BuildGiftDetailsPayloadInteractor < ApplicationInteractor
    def call # rubocop:disable Metrics/AbcSize
      return unless gift_message || shipment.giftwrapped?

      payload << { code: MIRAKL_DATA[:order][:additional_fields][:gift_message],
                   value: gift_message }
      payload << { code: MIRAKL_DATA[:order][:additional_fields][:gift_wrapped],
                   value: shipment.giftwrapped? }
      payload << { code: MIRAKL_DATA[:order][:additional_fields][:gift_wrap_customer_fee],
                   value: giftwrap&.giftwrap_total }
    rescue StandardError => e
      rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
    end

    private

    def mirakl_order
      context.mirakl_order
    end

    def gift_message
      mirakl_order.spree_order.gift_message
    end

    def shipment
      mirakl_order.shipment
    end

    def giftwrap
      shipment.giftwrap
    end

    def payload
      context.mirakl_order_additional_fields_payload ||= []
    end
  end
end
