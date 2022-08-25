# frozen_string_literal: true

module Salsify
  module Api
    private

    def auth_token
      @auth_token ||= Maisonette::Config.fetch('salsify.auth_token')
    end

    def api_endpoint
      @api_endpoint ||= Maisonette::Config.fetch('salsify.api_endpoint')
    end

    def organization_id
      @organization_id ||= Maisonette::Config.fetch('salsify.organization_id')
    end

    def get(api_method)
      rest_client_call(:get, api_method)
    end

    def post(api_method, payload: nil)
      rest_client_call(:post, api_method, payload: payload)
    end

    def put(api_method, payload: nil)
      rest_client_call(:put, api_method, payload: payload)
    end

    def delete(api_method, payload: nil)
      rest_client_call(:delete, api_method, payload: payload)
    end

    def rest_client_call(verb, api_method, payload: nil)
      full_url = File.join(api_endpoint, 'orgs', organization_id, api_method)
      args = [full_url,
              payload,
              { Authorization: "Bearer #{auth_token}",
                'Content-Type' => 'application/json' }].compact
      RestClient.public_send(verb, *args)
    rescue StandardError => e
      handle_rest_error(e)
      false
    end

    def handle_rest_error(exception)
      case exception
      when RestClient::ExceptionWithResponse
        Rails.logger.warn exception.inspect
        context.message = "status: #{exception.response&.code}, message: #{exception.response&.body}"
      when SocketError
        Rails.logger.warn exception.inspect
        context.message = "message: #{exception.message}"
      when StandardError
        Sentry.capture_exception_with_message(exception)
      end
    end
  end
end
