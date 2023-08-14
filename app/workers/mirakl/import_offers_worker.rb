# frozen_string_literal: true

module Mirakl
  class ImportOffersWorker
    include Sidekiq::Worker

    sidekiq_options lock: :until_executed, retry: false, unique_args: ->(_args) { true }

    def perform(date_time = updated_since)
      Mirakl::ImportOffersInteractor.call(updated_since: date_time)
    end

    def updated_since

      Mirakl::Update.offer.ordered_by_started_at_desc.first&.started_at&.iso8601
    end
  end
end
