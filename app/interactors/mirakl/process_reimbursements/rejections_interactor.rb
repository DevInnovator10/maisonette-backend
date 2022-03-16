# frozen_string_literal: true

module Mirakl
  module ProcessReimbursements
    class RejectionsInteractor < ApplicationInteractor
      include Mirakl::ProcessReimbursements::Reimbursements

      helper_methods :mirakl_order, :order_line_payload

      def call
        return unless order_line_payload['order_line_state'] == 'REFUSED'

        reimbursements << find_or_create_order_line_reimb
      rescue StandardError => e
        rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
      end

      private

      def find_or_create_order_line_reimb
        Mirakl::OrderLineReimbursement.find_by(
          mirakl_reimbursement_id: mirakl_order_line.mirakl_order_line_id,
          mirakl_type: 'rejection'
        ) || create_order_line_reimb
      end

      def create_order_line_reimb # rubocop:disable Metrics/AbcSize
        Mirakl::OrderLineReimbursement.new(
          mirakl_reimbursement_id: mirakl_order_line.mirakl_order_line_id,
          amount: order_line_payload['price'],
          tax: total_tax_amount(order_line_payload['taxes']),
          shipping_amount: order_line_payload['shipping_price'],
          shipping_tax: total_tax_amount(order_line_payload['shipping_taxes']),
          quantity: order_line_payload['quantity'],
          refund_reason: refund_reason,
          order_line: mirakl_order_line,
          mirakl_type: 'rejection',
          inventory_units: inventory_units(order_line_payload['quantity'])
        ).tap(&:calculate_total)
      end

      def refund_reason
        Spree::RefundReason.find_or_create_by!(name: MIRAKL_DATA[:order][:refund_reason][:rejected_by_vendor])
      end
    end
  end
end
