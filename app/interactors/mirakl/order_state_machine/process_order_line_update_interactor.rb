# frozen_string_literal: true

module Mirakl
  module OrderStateMachine
    class ProcessOrderLineUpdateInteractor < ApplicationInteractor
      helper_methods :mirakl_order

      def call

        mirakl_order.process_order_line_update!(mirakl_order.mirakl_payload['order_lines'])
      rescue StandardError => e
        rescue_and_capture(e, error_details: mirakl_order.mirakl_payload['order_lines'])
      end
    end
  end
end
