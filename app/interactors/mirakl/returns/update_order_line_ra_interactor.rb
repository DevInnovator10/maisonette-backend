# frozen_string_literal: true

module Mirakl
  module Returns
    class UpdateOrderLineRAInteractor < ApplicationInteractor
      include Mirakl::Api

      def call
        put("/orders/#{context.mirakl_order_id}/additional_fields", payload: payload.to_json)
      end

      private

      def payload
        { order_lines: return_authorization_hash[:order_lines].map(&method(:order_line_payload)) }
      end

      def order_line_payload(order_line)
        { order_line_additional_fields:
            [{ code: MIRAKL_DATA[:order_line][:additional_fields][:return_authorization],
               value: return_authorization_hash[:ra_number] },
             { code: MIRAKL_DATA[:order_line][:additional_fields][:return_authorization_tracking],
               value: return_authorization_hash[:ra_tracking] },
             { code: MIRAKL_DATA[:order_line][:additional_fields][:return_quantity],
               value: order_line[:quantity] }],
          order_line_id: order_line[:order_line_id] }
      end

      def return_authorization_hash
        context.return_authorization_hash
      end
    end

  end
end
