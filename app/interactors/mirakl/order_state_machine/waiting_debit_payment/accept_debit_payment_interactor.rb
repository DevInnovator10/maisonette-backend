# frozen_string_literal: true

module Mirakl
  module OrderStateMachine
    module WaitingDebitPayment
      class AcceptDebitPaymentInteractor < ApplicationInteractor
        include Mirakl::Api

        helper_methods :mirakl_order

        def call
          put('/payment/debit', payload: accept_debit_payload)
        rescue StandardError => e
          rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
        end

        private

        def mirakl_payload
          mirakl_order.mirakl_payload
        end

        def accept_debit_payload
          total_price_with_tax = BigDecimal(mirakl_payload['total_price'].to_s) + taxes

          { orders: [{ amount: total_price_with_tax.to_f,
                       currency_iso_code: mirakl_payload['currency_iso_code'],
                       customer_id: mirakl_payload['customer']['customer_id'],
                       order_id: mirakl_payload['order_id'],
                       payment_status: 'OK' }] }.to_json
        end

        def taxes
          mirakl_payload['order_lines'].select { |ol| ol['order_line_state'] == 'WAITING_DEBIT_PAYMENT' }
                                       .sum { |ol| total_tax_amount(ol['taxes']) }
        end

        def total_tax_amount(taxes)
          taxes.sum { |tax| BigDecimal(tax['amount'].to_s) }
        end
      end
    end
  end
end
