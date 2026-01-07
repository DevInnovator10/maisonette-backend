# frozen_string_literal: true

module Klaviyo
  class Client
    class DataPrivacy < Api
      attr_reader :client

      def initialize(client:)
        @client = client
      end

      def deletion_request(user_data)
        validate_deletion_request(user_data)

        response = post_request('api/v2/data-privacy/deletion-request', user_data, authorized_headers)
        response.code == 200 || Oj.load(response.body)['detail']
      end

      private

      def authorized_headers
        { 'api-key' => client.private_api_key }
      end

      def validate_deletion_request(user_data)
        return if (data = user_data.try(:dig, :email)) &&
                  data.is_a?(String)

        raise ::Klaviyo::Api::KlaviyoError, I18n.t(:invalid_deletion_request_data, scope: 'errors.klaviyo.data_privacy')
      end
    end
  end
end
