# frozen_string_literal: true

module Forter
  class ValidationInteractor < ApplicationInteractor
    required_params :order
    helper_methods :order, :result

    def call
      return unless Flipper.enabled?(:forter_fraud_validation)

      validation_payload = Forter::OrderPresenter.new(order).validation_payload
      context.result = Forter::Api::Client.validate_order(order, validation_payload)

      if result['status'] == 'failed'
        Sentry.capture_message('Issue with fraud validation',
                               extra: { order: order.attributes, forter_result: result })
        return
      end

      context.fail! if result['action'] == 'decline'
    end
  end
end
