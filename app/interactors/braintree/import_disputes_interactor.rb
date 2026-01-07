# frozen_string_literal: true

module Braintree
  class ImportDisputesInteractor < ApplicationInteractor
    after :check_missing_payments

    def call
      import_disputes
    end

    private

    def import_disputes
      context.missing_payments = []
      disputes.each do |dispute|
        spree_payment = Spree::Payment.find_by(response_code: dispute.transaction.id)
        @spree_payment_id = spree_payment.id if spree_payment.present?
        context.missing_payments << dispute.transaction.id if spree_payment.nil?

        import dispute
      end
    end

    def import(dispute)
      Reporting::Braintree::Dispute.create!(transaction_code: dispute.transaction.id,
                                            reason: dispute.reason,
                                            kind: dispute.kind,
                                            status: dispute.status,
                                            amount: dispute.amount_disputed,
                                            case_number: dispute.case_number,
                                            braintree_dispute_id: dispute.id,
                                            dispute_payload: dispute.to_json,
                                            spree_order_number: dispute.transaction.order_id,
                                            spree_payment_id: @spree_payment_id,
                                            received_date: dispute.received_date)
    end

    def disputes
      @disputes ||= gateway.dispute.search { |search| search.received_date <= Time.current }.disputes
    end

    def gateway
      @gateway ||= SolidusPaypalBraintree::Gateway.active.first.braintree
    end

    def check_missing_payments
      context.fail!(message: 'missing payments') unless context.missing_payments.empty?
    end
  end
end
