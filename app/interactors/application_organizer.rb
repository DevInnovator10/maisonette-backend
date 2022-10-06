# frozen_string_literal: true

class ApplicationOrganizer
  include Interactor::Organizer

  class << self
    def call(context = {})
      context ||= {}
      call_with_logging(context) { super }
    end

    def call!(context = {})
      context ||= {}
      call_with_logging(context) { super }
    end

    private

    def call_with_logging(context) # rubocop:disable Metrics/AbcSize
      Datadog.tracer.trace(name) do |span|
        span.set_tags(organizer: name)
        Rails.logger.tagged(name) do
          time = Time.current
          Rails.logger.info(context.to_h.merge(message: "started organizer #{name}"))
          context = yield
          duration = ((Time.current - time) * 1_000_000_000).to_i
          Rails.logger.info(context.to_h.merge(message: "finished organizer #{name}", duration: duration))
        end
      end
      context
    end
  end
end
