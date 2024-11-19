# frozen_string_literal: true

module Forter
  module Payments
    module CreditCard
      private

      def credit_card(payment, tag: :creditCard) # rubocop:disable Metrics/MethodLength
        payment_source = payment.payment_source
        braintree_payment_method = payment_source.braintree_payment_method
        return {} unless braintree_payment_method

        {
          tag.to_sym => {
            nameOnCard: braintree_payment_method.try(:cardholder_name),
            cardBrand: braintree_payment_method.card_type,
            bin: braintree_payment_method.bin,
            lastFourDigits: braintree_payment_method.last_4,
            expirationMonth: braintree_payment_method.expiration_month,
            expirationYear: braintree_payment_method.expiration_year,
            cardBank: braintree_payment_method.try(:issuing_bank),
            paymentGatewayData: { gatewayName: payment.payment_method.name,
                                  gatewayTransactionId: payment.response_code }
          }.merge(verification_results(payment))
        }
      end

      def verification_results(payment)
        return {} unless payment&.response_code

        braintree_transaction = payment.payment_source.braintree_transaction(payment)
        { verificationResults: { cvvResult: 'I',
                                 avsNameResult: payment.avs_response,
                                 processorResponseCode: braintree_transaction&.processor_response_code,
                                 processorResponseText: braintree_transaction&.processor_response_text } }
      end
    end
  end
end
