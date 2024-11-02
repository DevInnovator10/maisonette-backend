# frozen_string_literal: true

module Mirakl
  class AlertUnissuedInvoicesWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(*_args)
      Mirakl::AlertUnissuedInvoicesInteractor.call
    end
  end
end
