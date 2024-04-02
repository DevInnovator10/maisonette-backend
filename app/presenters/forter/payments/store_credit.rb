# frozen_string_literal: true

module Forter
  module Payments
    module StoreCredit
      private

      def store_credit(payment)
        { storeCreditUsed: { merchantPaymentId: payment.response_code.to_s,
                             value: { amountUSD: payment.amount.to_s,
                                      currency: payment.currency },
                             activationTime: payment.payment_source.created_at.to_i,
                             originalValue: { amountUSD: payment.payment_source.amount.to_s,
                                              currency: payment.payment_source.currency },

                             creditOrigin: payment.payment_source.memo } }
      end
    end
  end
end
