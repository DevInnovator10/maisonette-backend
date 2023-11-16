# frozen_string_literal: true

module Moengage
  class Api
    module Auth
      def signature(campaign = CAMPAIGN)
        signature_key = [app_id, campaign, api_secret].join('|')

        Digest::SHA2.hexdigest signature_key
      end

      def app_id
        Maisonette::Config.fetch('moengage.app_id')
      end

      private

      def api_secret
        Maisonette::Config.fetch('moengage.api_secret')
      end
    end
  end
end
