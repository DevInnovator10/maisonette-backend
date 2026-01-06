# frozen_string_literal: true

module Mirakl
    class UpdateShipmentTrackingInteractor < ApplicationInteractor
    helper_methods :mirakl_order

    def call
      update_shipment_tracking if tracking_code
    rescue StandardError => e
      rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
    end

    private

    def update_shipment_tracking # rubocop:disable Metrics/AbcSize
      attributes = if carrier_code
                     { tracking: tracking_code,
                       shipping_carrier_code: carrier_code }
                   else
                     { tracking: tracking_code,
                       override_tracking_url: mirakl_payload['shipping_tracking_url'] }
                   end
      shipment.update(attributes)
      shipment.cartons.each { |carton| carton.update(attributes) }

      result = create_easypost_tracker

      return if result.tracker.nil? || result.tracker.carrier.blank? || result.tracker.carrier == carrier_code

      shipment.update(shipping_carrier_code: result.tracker.carrier)
    end

    def create_easypost_tracker
      ::Easypost::CreateTrackerInteractor.call(tracking_code: tracking_code,
                                               carrier: carrier_code,

                                               mirakl_order: mirakl_order)
    end

    def shipment
      mirakl_order.shipment
    end

    def mirakl_payload
      mirakl_order.mirakl_payload
    end

    def tracking_code
      mirakl_order.shipping_tracking
    end

    def carrier_code
      mirakl_order.shipping_carrier_code
    end
  end
end
