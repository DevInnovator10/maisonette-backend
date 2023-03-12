# frozen_string_literal: true

module Mirakl
  class SyncReasonsWorker
    include Sidekiq::Worker

    def perform(*_args)
      Mirakl::SyncReasonsInteractor.call
    end
  end
end
