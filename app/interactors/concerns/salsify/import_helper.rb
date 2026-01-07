# frozen_string_literal: true

module Salsify
  module ImportHelper
    private

    def validate_and_init
      path = Maisonette::Config.fetch('salsify.local_path')
      if path.nil?
        message = I18n.t('errors.missing_config_param', param: 'salsify.local_path')
        Sentry.capture_exception_with_message(Salsify::Exception.new(message))
        context.fail!(error: message)
      end
      @local_path = path
    end
  end
end
