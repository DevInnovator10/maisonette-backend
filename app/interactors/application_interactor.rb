# frozen_string_literal: true

class ApplicationInteractor
  class MissingParams < StandardError; end

  include Interactor

  class << self
    def required_params(*args)
      @required_params ||= args.flatten.map(&:to_sym)
    end

    def helper_methods(*args)
      @helper_methods ||= args.flatten.map(&:to_sym)
    end

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
        span.set_tags(interactor: name)
        Rails.logger.tagged(name) do
          time = Time.current
          Rails.logger.info(context.to_h.merge(message: "started interactor #{name}"))
          context = yield
          duration = ((Time.current - time) * 1_000_000_000).to_i
          Rails.logger.info(context.to_h.merge(message: "finished interactor #{name}", duration: duration))
        end
      end
      context
    end
  end

  def initialize(input = {})
    super
    fail_if_missing_params
    set_helper_methods
  end

  private

  def rescue_and_capture(exception, error_details: nil, extra: {})
    error_message = I18n.t('errors.interactor.rescue',
                           class_name: self.class.name,
                           error_details: error_details)
    context.exception = exception

    log_event(:error, "#{error_details}\n#{extra}")
    Sentry.capture_exception_with_message(exception, message: error_message, extra: extra)
    false
  end

  def missing_params
    self.class.required_params - context.to_h.symbolize_keys.keys
  end

  def fail_if_missing_params
    return if missing_params.empty?

    raise ApplicationInteractor::MissingParams, I18n.t('errors.interactor.params', params: missing_params.to_sentence)
  end

  def set_helper_methods
    self.class.helper_methods.each do |method|
      self.class.define_method(method) do
        instance_variable_get("@#{method}") ||
          instance_variable_set("@#{method}", context.public_send(method))
      end
      self.class.send(:private, method)
    end
  end

  def log_event(level, message, **extra)
    log_message = I18n.t('errors.interactor.log_event',
                         class_name: self.class.name,
                         message: message)
    Rails.logger.send(level.to_sym, message: log_message, **context.to_h, **extra)
  rescue StandardError => e
    Sentry.capture_exception_with_message(e, error_details: 'failed to log event')
  end
end
