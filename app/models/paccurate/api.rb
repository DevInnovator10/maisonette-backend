# frozen_string_literal: true

module Paccurate
  module Api

    PACCURATE_API_URL = 'https://api.paccurate.io/'

    extend self

    def pack(paccurate_payload)
      sanitized_payload = Oj.generate paccurate_payload.deep_stringify_keys
      response = RestClient.post(PACCURATE_API_URL, sanitized_payload, default_headers)
      return Oj.load response.body if response.code == 200

      raise Error, "Paccurate API failure, code: #{response.code}"
    rescue StandardError => e
      raise(e) if e.is_a?(Paccurate::Api::Error)

      Sentry.capture_exception_with_message Error.new(e)
      false
    end

    private

    def paccurate_api_key
      Maisonette::Config.fetch('paccurate.api_key') || raise(Error, 'Missing api key')
    end

    def default_headers
      { Authorization: "apikey #{paccurate_api_key}", accept: :json, content_type: :json }
    end

    class Error < StandardError
      def initialize(error = nil)
        super error
        set_backtrace caller
      end
    end
  end
end
