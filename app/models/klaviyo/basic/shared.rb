# frozen_string_literal: true

require 'addressable/uri'

module Klaviyo
  module Basic
    module Shared
      private

      def encode_with_auth(payload)
        json_payload_with_auth = Oj.generate(payload.merge(token: public_api_key))
        addressable = ::Addressable::URI.parse Base64.encode64(json_payload_with_auth)
        addressable.to_s.gsub(/\n/, '')
      end

      def verify_user(opts)
        return if opts['email'] || opts['id']

        raise ::Klaviyo::Api::KlaviyoError, I18n.t(:email_or_id_required, scope: 'errors.klaviyo.basic')
      end

      def success?(response)
        response.body == '1'
      end
    end
  end
end
