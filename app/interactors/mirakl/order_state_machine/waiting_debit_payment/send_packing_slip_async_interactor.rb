# frozen_string_literal: true

module Mirakl
  module OrderStateMachine
    module WaitingDebitPayment
      class SendPackingSlipAsyncInteractor < ApplicationInteractor
        helper_methods :mirakl_order

        def call
          ::Mirakl::SendPackingSlipWorker.perform_async(mirakl_order.logistic_order_id)
        end
      end
    end
  end
end
