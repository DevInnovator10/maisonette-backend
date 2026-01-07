# frozen_string_literal: true

module SolidusAfterpay::PaymentSource::Status
  REFUNDABLE_STATUSES = %w[
    PARTIALLY_CAPTURED
    CAPTURED
  ].freeze

  def can_refund?(payment)
    return false unless payment.response_code

    gateway = payment.payment_method.gateway
    payment_state = gateway.find_payment(order_id: payment.response_code).try(:[], :paymentState)

    REFUNDABLE_STATUSES.include?(payment_state)
  rescue ::Afterpay::BaseError
    false
  end
end
