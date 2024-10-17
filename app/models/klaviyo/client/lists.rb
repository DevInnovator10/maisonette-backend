# frozen_string_literal: true

module Klaviyo
  class Client
    class Lists < Api
      attr_reader :client, :list_id

      def initialize(client:, list_id: nil)
        @client = client
        @list_id = list_id
      end

      def all
        response = get_request('api/v2/lists', nil, authorized_headers)
        Oj.load response.body
      end

      def show
        validate_list
        response = get_request("api/v2/list/#{list_id}", nil, authorized_headers)
        Oj.load response.body
      end

      def fetch_subscribers(users)
        validate_list
        users = Array.wrap(users)
        validate_subscribers(users)

        user_params = users.map do |user|
          email = "emails=#{CGI.escape(user[:email])}" if user[:email]
          # TODO: Phone format must be E.164 otherwise an error is returned for the whole call!
          # phone_number = "phone_numbers#{user[:phone_number]}" if user[:phone_number]

          [email].compact.join('&')
        end.join('&')

        response = get_request("api/v2/list/#{list_id}/subscribe?#{user_params}", nil, authorized_headers)
        Oj.load response.body
      end

      def subscribe(users)
        validate_list
        users = Array.wrap(users)
        validate_subscribers(users)

        payload = { profiles: users }

        response = post_request("api/v2/list/#{list_id}/subscribe", payload, authorized_headers)
        Oj.load response.body
      end

      def unsubscribe(user_data)
        validate_list
        validate_unsubscribe(user_data)

        response = delete_request("api/v2/list/#{list_id}/subscribe", user_data, authorized_headers)
        response.code == 200 || Oj.load(response.body)['detail']
      end

      private

      def authorized_headers
        { 'api-key' => client.private_api_key }
      end

      def validate_list
        return if list_id

        raise ::Klaviyo::Api::KlaviyoError, I18n.t(:invalid_list_id, scope: 'errors.klaviyo.lists')
      end

      def validate_subscribers(users_array)
        users_array.each do |user_data|
          next if user_data.try(:dig, :email) || user_data.try(:dig, :phone_number)

          raise ::Klaviyo::Api::KlaviyoError, I18n.t(:invalid_subscribe_data, scope: 'errors.klaviyo.lists')
        end
      end

      def validate_unsubscribe(user_data)
        return if (data = user_data.try(:dig, :emails) ||
                          user_data.try(:dig, :phone_numbers) ||
                          user_data.try(:dig, :push_tokens)) &&
                  data.is_a?(Array)

        raise ::Klaviyo::Api::KlaviyoError, I18n.t(:invalid_unsubscribe_data, scope: 'errors.klaviyo.lists')
      end
    end
  end
end
