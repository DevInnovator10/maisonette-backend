# frozen_string_literal: true

module Mirakl
  module ProcessReimbursements
    class RefundsInteractor < ApplicationInteractor
      include Mirakl::ProcessReimbursements::Reimbursements

      helper_methods :order_line_payload, :mirakl_order

      def call
        return unless order_line_payload['refunds']

        find_or_create_reimbursements(order_line_payload['refunds'], 'refund')

        fetch_order_line_reimbursements

        send_refund_notifications

        # rubocop:disable Rails/SkipsModelValidations
        context.new_refund_order_line_reimbursements.update_all(refund_processing_sent_at: Time.zone.now)
        # rubocop:enable Rails/SkipsModelValidations
      rescue StandardError => e
        rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
      end

      private

      def fetch_order_line_reimbursements
        context.new_refund_order_line_reimbursements = mirakl_order.order_line_reimbursements.where(
          refund_processing_sent_at: nil,
          state: 'NEW'

        ).refund
      end

      def send_refund_notifications
        return if context.new_refund_order_line_reimbursements.blank?

        Mirakl::RefundProcessingMailer.refund_email(context.new_refund_order_line_reimbursements.map(&:id),
                                                    'refund', promo_code: nil).deliver_later

        return unless order&.channel == 'ios'

        Moengage::OrderRefundedNotificationWorker.perform_async(order.id, total_refund_amount.to_s)
      end

      def order
        return nil if context.new_refund_order_line_reimbursements.empty?

        context.new_refund_order_line_reimbursements[0].line_item.order
      end

      def total_refund_amount
        context.new_refund_order_line_reimbursements.sum(&:total)
      end
    end
  end
end
