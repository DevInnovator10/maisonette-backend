# frozen_string_literal: true

json.address_verification do # rubocop:disable Metrics/BlockLength
  return unless address_verification

  json.address do
    json.street1(address_verification.street1)
    json.street2(address_verification.street2)
    json.city(address_verification.city)
    json.state(address_verification.state)
    json.zip(address_verification.zip)
    json.country(address_verification.country)
  end

  easypost_verifications = address_verification.verifications
  verifications = if easypost_verifications.respond_to?(:zip4)
                    easypost_verifications.zip4
                  else
                    easypost_verifications.delivery
                  end

  json.success(verifications.success)

  json.suggestions do
    json.array!(verifications.errors) do |error|
      json.field(error.field)
      json.message(error.message)
      json.suggestion(error.suggestion)
    end
  end
rescue StandardError => e
  message = "Failed to respond with easypost address for #{order.number}"
  Sentry.capture_exception_with_message(e, message)
  return
end
