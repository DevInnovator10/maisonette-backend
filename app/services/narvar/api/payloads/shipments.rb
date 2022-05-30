# frozen_string_literal: true

module Narvar
  module Api
    module Payloads
      class Shipments
        def initialize(order)
          @order = order
        end

        def payload
          return {} unless @order

          {
            order_info: {
              shipments: @order.shipments.shipped.where.not(shipped_at: nil).map { |sm| payload_shipment(sm) }

            }
          }
        end

        private

        def fallback_tracking(order, id)
          "NOTRK-#{order.number}-#{id}"
        end

        def payload_shipment(shipment) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          stock = shipment.stock_location
          address = @order.ship_address

          {
            attributes: {
              signature_required: nil,
              custom_attribute1: nil,
              custom_attribute2: nil,
              logistic_order_id: logistic_order(shipment.mirakl_order&.logistic_order_id.to_s, stock)

            },
            ship_source: nil,
            carrier: shipment.mirakl_order&.shipping_carrier_code,
            tracking_number: shipment.tracking || fallback_tracking(@order, shipment.id),
            ship_method: shipment.shipping_method&.admin_name,
            carrier_service: shipment.mirakl_order&.shipping_carrier_code,
            promise_date: nil,
            items_info: shipment.line_items.map { |li| { quantity: li.quantity, sku: li.sku, item_id: li.id } },
            shipped_to: {
              first_name: address&.firstname,
              last_name: address&.lastname,
              phone: address&.phone,
              phone_extension: nil,
              email: @order.email,
              fax: nil,
              address: {
                street_1: address&.address1,
                street_2: address&.address2,
                city: address&.city,
                state: address&.state&.abbr,
                zip: address&.zipcode,
                country: address&.country&.iso
              }
            },
            shipped_from: {
              first_name: stock.name,
              last_name: nil,
              phone: stock.phone,
              email: nil,
              fax: nil,
              address: {
                street_1: stock.address1,
                street_2: stock.address2,
                city: stock.city,
                state: stock.state&.abbr || stock.state_name,
                zip: stock.zipcode,
                country: stock.country&.iso
              }
            },
            ship_discount: nil,
            ship_total: nil,
            ship_tax: nil,
            ship_date: shipment.shipped_at&.to_formatted_s(:iso8601)
          }
        end

        def logistic_order(logistic_order_id, stock)
          stock.maisonette_fulfillment? ? 'MA-' + logistic_order_id : logistic_order_id
        end
      end
    end
  end
end
