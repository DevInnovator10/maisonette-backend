# frozen_string_literal: true

module Klaviyo
  class TrackerWorker
    include Sidekiq::Worker

    def perform(gid, event)
      context = Klaviyo::TrackerInteractor.call(gid: gid, event: event)
      Sentry.capture_message(context.message) if context.failure?
    end
  end
end
