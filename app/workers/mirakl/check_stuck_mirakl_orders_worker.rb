# frozen_string_literal: true

module Mirakl
    class CheckStuckMiraklOrdersWorker
    include Sidekiq::Worker

    sidekiq_options lock: :while_executing, retry: false

    def perform(*_args)
      Mirakl::Order.where(state: :WAITING_DEBIT_PAYMENT).where('updated_at < ?', 1.hour.ago).find_each do |mirakl_order|
        Sentry.capture_message("Order stuck in state: #{mirakl_order.state} - #{mirakl_order.logistic_order_id}",
                               tags: { notify: :order_sync_issues })
      end
    end
  end
end
