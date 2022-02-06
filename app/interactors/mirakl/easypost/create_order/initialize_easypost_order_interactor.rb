# frozen_string_literal: true

module Mirakl
  module Easypost
    module CreateOrder
      class InitializeEasypostOrderInteractor < ApplicationInteractor
        helper_methods :mirakl_order, :boxes

        def call # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          return if shipment.mirakl_shop.manage_own_shipping?

          context.easypost_order = easypost_order = shipment.easypost_orders.new
          easypost_order.fetch_api_key
          boxes.each do |box|
            create_parcel(box, easypost_order)
          end
        rescue EasyPost::Error => e
          log_event(:error, "#{e.message} - #{mirakl_order.logistic_order_id}")
          context.easypost_exception = e
          easypost_order.fetch_and_send_easypost_error
        rescue StandardError => e
          rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
          context.error_message = e.message
        end

        private

        def create_parcel(box, easypost_order)
          parcel = easypost_order.easypost_parcels.new(length: box[:length], width: box[:width],
                                                       height: box[:height], weight: box[:weight])
          parcel.create_easypost_parcel(easypost_api_key: easypost_order.easypost_api_key)
        end

        def shipment
          mirakl_order.shipment
        end
      end
    end
  end
end
