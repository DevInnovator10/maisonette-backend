# frozen_string_literal: true

module LoggingHelper
  private

  def log_event(level, message)
    log_message = I18n.t('errors.helpers.log_event',
                         class_name: self.class.name,
                         message: message)
    Rails.logger.send(level.to_sym, log_message)
  rescue StandardError => e
    Sentry.capture_exception_with_message(e, message: 'failed to log event')
  end
end
