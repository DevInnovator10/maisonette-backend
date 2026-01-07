# frozen_string_literal: true

module Klaviyo
  class SyncSubscribersWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform
      Klaviyo::SyncSubscribersInteractor.call!
    end
  end
end
