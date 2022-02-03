# frozen_string_literal: true

module Mirakl
  class CancelOrderInteractor < ApplicationInteractor
    include Mirakl::Api

    def call
      put("/orders/#{context.logistic_order_id}/cancel")
    end
  end
end
