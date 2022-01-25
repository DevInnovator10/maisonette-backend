# frozen_string_literal: true

module RestClientMiddlewares
  class JsonLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env).tap do |response|
        log_request(response, env)
      end
    end

    private

    def log_request(response, env)
      status, headers, body = response
      Rails.logger.info(json_log(body, env, headers, status))
    rescue StandardError => e
      Sentry.capture_exception_with_message(e)
    end

    def json_log(body, env, headers, status)
      { request: { method: env['REQUEST_METHOD'],
                   server: env['SERVER_NAME'],
                   path: env['PATH_INFO'],
                   query: env['QUERY_STRING'],
                   port: env['SERVER_PORT'],
                   content_type: env['CONTENT_TYPE'],
                   content_length: env['CONTENT_LENGTH'],
                   body: parsed_request_body(env) },
        response: { status: status,
                    headers: headers,
                    body: parsed_response_body(body),
                    error: env['restclient.hash'][:error] } }
    end

    def parsed_response_body(body)
      return unless body[0].is_utf8?

      Oj.load(body[0])
    rescue StandardError
      body
    end

    def parsed_request_body(env)
      input = env['rack.input']
      input.rewind
      input_string = input.read
      return unless input_string.is_utf8?
      return if input_string.blank?

      Oj.load(input_string)
    rescue Oj::Error, JSON::ParserError
      input_string

    end
  end
end
