# frozen_string_literal: true

module Spree
    class AvalaraFinalizeOrderWorker
    include Sidekiq::Worker

    def perform(spree_order_number)
      order = Spree::Order.find_by(number: spree_order_number)
      order.avalara_capture_finalize
    end
  end
end
