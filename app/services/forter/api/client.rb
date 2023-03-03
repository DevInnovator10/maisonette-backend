# frozen_string_literal: true

module Forter
  module Api
    class Client
      include Singleton

      attr_reader :site_id, :secret_key, :api_version, :api_path

      def initialize
        @site_id = Maisonette::Config.fetch('forter.site_id')
        @secret_key = Maisonette::Config.fetch('forter.secret_key')
        @api_version = Maisonette::Config.fetch('forter.api_version')
        @api_path = Maisonette::Config.fetch('forter.api_path')
      end

      class << self
        def validate_order(order, payload)
          response = RestClient.post(
            api_url("orders/#{order.number}"),
            payload.to_json,
            content_type: :json,
            accept: :json,
            'api-version': instance.api_version
          )

          JSON.parse(response.body)
        rescue RestClient::ExceptionWithResponse => e
          JSON.parse(e.response)
        end

        def update_order_status(order, payload)
          response = RestClient.post(
            api_url("status/#{order.number}"),
            payload.to_json,
            content_type: :json,
            accept: :json,
            'api-version': instance.api_version
          )

          JSON.parse(response.body)
        rescue RestClient::ExceptionWithResponse => e
          JSON.parse(e.response)
        end

        private

        def api_url(service)
          "https://#{instance.secret_key}:@#{instance.site_id}.#{instance.api_path}#{service}"
        end
      end
    end
  end
end
