# frozen_string_literal: true

module Klaviyo
  class Api
    class KlaviyoError < StandardError; end
    include Verbs
    include Auth

    KLAVIYO_API_URL = 'https://a.klaviyo.com/'

    private

    def default_headers
      { accept: :json, content_type: :json }
    end
  end
end
