# frozen_string_literal: true

module Klaviyo
  class ListSubscriberWorker
    include Sidekiq::Worker

    def perform(id)
      subscriber = Maisonette::Subscriber.find_by(id: id)
      context = Klaviyo::ListSubscriberInteractor.call(subscriber: subscriber)
      Sentry.capture_message(context.message) if context.failure? && !context.invalid_email_address
    end
  end
end
