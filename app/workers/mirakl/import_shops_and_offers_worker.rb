# frozen_string_literal: true

module Mirakl
  class ImportShopsAndOffersWorker
    include Sidekiq::Worker

    sidekiq_options lock: :until_executed,
                    retry: false,
                    log_duplicate_payload: true

    def perform(*_args)
      ImportShopsWorker.new.perform
      ImportOffersWorker.perform_async
    end
  end
end
