# frozen_string_literal: true

module OrderManagement
  class PaymentPresenter
    PAYMENT_GATEWAY_ID = Maisonette::Config.fetch('order_management.payment_gateway_id')
    AFTERPAY_GATEWAY_REF_NUMBER = Maisonette::Config.fetch('order_management.afterpay_gateway_ref_number')

    def initialize(payment, payment_source_index, grouped_payments)
      @payment = payment
      @payment_source_index = payment_source_index
      @grouped_payments = grouped_payments
    end

    def payload # rubocop:disable Metrics/MethodLength
      {
        attributes: { type: 'Payment' },
        Amount: amount,
        ProcessingMode: 'External',
        Status: 'Processed',
        PaymentGroupId: '@{refPaymentGroup.id}',
        AccountId: '@{refAcc.id}',
        PaymentMethodId: "@{refPaymentSources[#{@payment_source_index}].id}",
        PaymentGatewayId: PAYMENT_GATEWAY_ID,
        GatewayRefNumber: gateway_ref_number,
        Payment_Number__c: payment_number,
        Type: 'Capture'
      }.tap do |payload|
        payload[:Store_Credit_Info__c] = format_grouped_payments if @grouped_payments.any?
      end
    end

    private

    def amount
      @payment.source_type == 'Spree::GiftCard' ? -@payment.amount.to_f : @payment.amount.to_f
    end

    def payment_number
      return @payment.number unless @payment.source_type == 'Spree::GiftCard'

      @payment.source.promotion_code.value
    end

    def gateway_ref_number
      if @payment&.source_type == 'SolidusAfterpay::PaymentSource'
        AFTERPAY_GATEWAY_REF_NUMBER
      elsif @payment.source_type == 'Spree::GiftCard'
        @payment.source.promotion_code.value
      else
        @payment.response_code
      end
    end

    def format_grouped_payments
      @grouped_payments.map { |payment| "#{payment.number}:#{payment.amount.to_f}" }.join(',')
    end
  end
end
