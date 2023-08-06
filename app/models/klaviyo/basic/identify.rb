# frozen_string_literal: true

module Klaviyo
  module Basic
    module Identify
      include Shared

      ENDPOINT = 'api/identify'
      SPECIAL_IDENTIFY_PROPERTIES = %w[
        id email first_name last_name phone_number title organization city region country zip image consent
      ].freeze

      def identify(properties)
        properties.deep_stringify_keys!
        verify_user(properties)

        properties.transform_keys! { |k| SPECIAL_IDENTIFY_PROPERTIES.include?(k) ? "$#{k}" : k }

        response = get_request(ENDPOINT, data: encode_with_auth('properties' => properties))
        success?(response)
      end
    end
  end
end
