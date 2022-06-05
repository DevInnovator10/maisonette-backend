# frozen_string_literal: true

module Moengage
  class Client < Api
    def push(email:, notification:)
      payload = payload(email, notification)

      RestClient.post(
        MOENGAGE_API_URL,
        sanitized(payload),
        default_headers
      )
    end

    private

    def sanitized(payload)
      Oj.generate payload.deep_stringify_keys
    end

    def payload(email, notification) # rubocop:disable Metrics/MethodLength
      {
        appId: app_id,
        campaignName: CAMPAIGN,
        signature: signature,
        requestType: 'push',
        targetAudience: 'User',
        customSegmentName: 'User',
        targetUserAttributes: {
          attribute: 'USER_ATTRIBUTE_USER_EMAIL',
          comparisonParameter: 'is',
          attributeValue: email
        },
        targetPlatform: ['IOS'],
        payload: {
          IOS: {
            "message": notification.message,
            "title": notification.title,
            "subtitle": notification.subtitle
          }
        },
        campaignDelivery: {
          type: 'soon'
        }
      }
    end
  end
end
