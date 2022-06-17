# frozen_string_literal: true

module Mirakl
  module ProcessReimbursements
    class CancelationsInteractor < ApplicationInteractor
      include Mirakl::ProcessReimbursements::Reimbursements

      helper_methods :order_line_payload, :mirakl_order

      def call
        return unless order_line_payload['cancelations']

        find_or_create_reimbursements(order_line_payload['cancelations'], 'cancelation')
      rescue StandardError => e
        rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
      end
    end
  end
end
