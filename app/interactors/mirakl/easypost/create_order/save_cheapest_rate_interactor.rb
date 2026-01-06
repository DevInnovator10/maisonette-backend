# frozen_string_literal: true

module Mirakl
  module Easypost
    module CreateOrder
      class SaveCheapestRateInteractor < ApplicationInteractor
        helper_methods :easypost_order, :mirakl_order

        def call
          return unless easypost_order

          easypost_order.create_easypost_order
          easypost_order.select_cheapest_rate
          easypost_order.save! unless context.skip_save
        rescue EasyPost::Error => e
          log_event(:error, "#{e.message} - #{mirakl_order.logistic_order_id}")
          context.easypost_exception = e
        rescue StandardError => e
          rescue_and_capture(e, extra: { mirakl_logistic_order_id: mirakl_order.logistic_order_id })
          context.easypost_exception = e
        end
      end
    end
  end
end
