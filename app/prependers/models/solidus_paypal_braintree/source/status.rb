# frozen_string_literal: true

module SolidusPaypalBraintree::Source::Status
  REFUNDABLE_STATUSES = [
    Braintree::Transaction::Status::Settling,
    Braintree::Transaction::Status::Settled,
  ].freeze

  def can_refund?(payment)
    return false unless payment.response_code

    transaction = protected_request do
      braintree_client.transaction.find(payment.response_code)
    end
    REFUNDABLE_STATUSES.include?(transaction.status)
  rescue ActiveMerchant::ConnectionError
    false
  end
end
