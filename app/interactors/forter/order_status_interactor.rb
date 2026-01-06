# frozen_string_literal: true

module Forter
  class OrderStatusInteractor < ApplicationInteractor
    required_params :order
    helper_methods :order, :failed_payment_id, :result

    def call
      return unless Flipper.enabled?(:forter_fraud_validation)

      validation_payload = Forter::OrderPresenter.new(order, failed_payment_id: failed_payment_id).order_status_payload
      context.result = Forter::Api::Client.update_order_status(order, validation_payload)

      return unless result['status'] == 'failed'

      Sentry.capture_message('Issue with updating fraud order status',
                             extra: { order: order.attributes, forter_result: result })
      context.fail!
    end
  end
end
