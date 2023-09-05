# frozen_string_literal: true

module Sentry::Client::CaptureExceptionWithMessage
    def event_from_exception_with_message(exception, message = nil, hint = {})
    integration_meta = Sentry.integrations[hint[:integration]]
    return unless @configuration.exception_class_allowed?(exception)

    Sentry::Event.new(configuration: configuration, integration_meta: integration_meta, message: message).tap do |event|
      event.add_exception_interface(exception)
      event.add_threads_interface(crashed: true)
    end
  end
end
