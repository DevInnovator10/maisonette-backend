# frozen_string_literal: true

module Mirakl
    class OrderReceptionAndInvoicesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :mirakl_order_fulfilment

    def perform(*_args)
      Mirakl::OrderConfirmReceptionWorker.new.perform
      Mirakl::ShopCreditsInvoiceWorker.perform_in(10.minutes)
      Mirakl::ShopFeesInvoiceWorker.perform_in(20.minutes)
    end
  end
end
