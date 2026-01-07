# frozen_string_literal: true

module Moengage
  class Api
    class MoengageError < StandardError; end
    include Auth

    MOENGAGE_API_URL = 'http://api-01.moengage.com/v2/transaction/sendpush'
    CAMPAIGN         = 'Maisonette Backend Push Notifications'

    private

    def default_headers
      { accept: :json, content_type: :json }
    end
  end
end
