# frozen_string_literal: true

module Braintree
  class DisputeInteractor < ApplicationInteractor
    before :webhook_notification
    after :check_for_missing_payment

    def call
      import
    end

    private

    def webhook_notification
      @webhook_notification ||= gateway.webhook_notification.parse(context.bt_signature, context.bt_payload)
      context.fail!(message: 'Non dispute webhook') unless @webhook_notification.kind.include?('dispute')

      @webhook_notification
    rescue Braintree::InvalidSignature
      context.fail!(message: 'Webhook hit with invalid signature')
    end

    def gateway
      @gateway ||= SolidusPaypalBraintree::Gateway.active.first.braintree
    end

    def dispute_attributes # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      {
        transaction_code: dispute.transaction&.id,
        reason: dispute.reason,
        kind: dispute.kind,
        status: dispute.status,
        amount: dispute.amount_disputed,
        case_number: dispute.case_number,
        braintree_dispute_id: dispute.id,
        dispute_payload: dispute.to_json,
        spree_order_number: dispute.transaction&.order_id,
        spree_payment_id: spree_payment_id,
        received_date: dispute.received_date
      }
    end

    def import
      braintree_dispute = Reporting::Braintree::Dispute.find_or_initialize_by(
        braintree_dispute_id: dispute_attributes[:braintree_dispute_id]
      )
      braintree_dispute.assign_attributes(dispute_attributes)
      braintree_dispute.save!
    rescue StandardError => e
      extra = dispute_attributes.slice(:dispute_payload, :spree_order_number, :transaction_code)
      Sentry.capture_exception_with_message(e, extra: extra)
      raise e
    end

    def dispute
      @dispute ||= webhook_notification.dispute
    end

    def spree_payment
      @spree_payment ||= Spree::Payment.find_by(response_code: dispute.transaction.id)
    end

    def spree_payment_id
      @spree_payment_id ||= spree_payment.id if spree_payment.present?
    end

    def check_for_missing_payment
      context.message, context.missing_payment = 'Missing payment', dispute.transaction.id if spree_payment_id.nil?
    end
  end
end
