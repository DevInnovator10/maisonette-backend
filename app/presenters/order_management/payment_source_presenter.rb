# frozen_string_literal: true

module OrderManagement
  class PaymentSourcePresenter
    DIGITAL_WALLET_PAYMENT_GATEWAY_ID = Maisonette::Config.fetch('order_management.digital_wallet_payment_gateway_id')
    AFTERPAY_PAYMENT_GATEWAY_ID = Maisonette::Config.fetch('order_management.afterpay_payment_gateway_id')
    CARD_PAYMENT_GATEWAY_ID = Maisonette::Config.fetch('order_management.card_payment_gateway_id')

    def initialize(source)
      @source = source
    end

    def payload
      case @source
      when ::SolidusPaypalBraintree::Source
        card_payment_payload
      when ::SolidusAfterpay::PaymentSource
        afterpay_payment_source
      else
        digital_wallet_payload
      end
    end

    private

    def digital_wallet_payload
      {
        attributes: { type: 'DigitalWallet' },
        Type: @source,
        AccountId: '@{refAcc.id}',
        Status: 'Active',
        ProcessingMode: 'External',
        GatewayToken: '2020',
        PaymentGatewayId: DIGITAL_WALLET_PAYMENT_GATEWAY_ID
      }
    end

    def card_payment_payload
      {
        attributes: { type: 'CardPaymentMethod' },
        CardCategory: format_card_category,
        AccountId: '@{refAcc.id}',
        Status: 'Active',
        ProcessingMode: 'External',
        CardType: format_card_type,
        ExpiryYear: expiration_year,
        ExpiryMonth: expiration_month,
        CardLastFour: card_last_four,
        PaymentGatewayId: CARD_PAYMENT_GATEWAY_ID
      }
    end

    def afterpay_payment_source
      {
        attributes: { type: 'DigitalWallet' },
        Type: 'AfterPay',
        GatewayToken: '2020',
        PaymentGatewayId: AFTERPAY_PAYMENT_GATEWAY_ID,
        Status: 'Active',
        AccountId: '@{refAcc.id}',
        AfterPay_Order_ID__c: @source.payments.first.response_code,
        ProcessingMode: 'External'
      }
    end

    def format_card_type
      return 'Paypal' if @source.paypal?

      @source.card_type == 'MasterCard' ? 'Master Card' : @source.card_type
    end

    def format_card_category
      @source.paypal? ? 'CreditCard' : @source.payment_type
    end

    def card_last_four
      return if !@source.credit_card?

      @source.last_4
    end

    def expiration_month
      return if @source.paypal?

      @source.expiration_month
    end

    def expiration_year
      return if @source.paypal?

      @source.expiration_year
    end
  end
end
