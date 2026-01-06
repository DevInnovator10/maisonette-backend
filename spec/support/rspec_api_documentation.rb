# frozen_string_literal: true

RspecApiDocumentation.configure do |config|
  config.api_name = 'Maisonette backend API documentation'
  config.format = [:open_api, :slate]
  config.docs_dir = Rails.root.join('tmp', 'api_docs')
end

module RspecApiDocumentation
  class RackTestClient < ClientBase
    def response_body
      last_response.body.encode('utf-8')
    end
  end
end
