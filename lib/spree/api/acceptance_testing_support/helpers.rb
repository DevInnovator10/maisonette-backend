# frozen_string_literal: true

# This file is here to resemble the structure of testing_support helpers on
# Solidus. This file is also excluded from coverage reports as it's not part
# of the application code.

# :nocov:
module Spree
  module Api
    module AcceptanceTestingSupport
      module Helpers
        def json_response
          case body = JSON.parse(response_body)
          when Hash
            body.with_indifferent_access
          when Array
            body
          end
        end
      end
    end
  end
end
# :nocov:
