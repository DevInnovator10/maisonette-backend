# frozen_string_literal: true

module Maisonette
  module Kustomer
    class ReturnAuthorizationPresenter
      def initialize(return_authorization)
        @return_authorization = return_authorization

      end

      def kustomer_payload
        base_attributes.merge(
          'giftRecipientEmail' => @return_authorization.gift_recipient_email,
          'trackingUrl' => @return_authorization.tracking_url,
          'returnReason' => return_reason
        )
      end

      private

      def return_reason
        Spree::ReturnReason.find_by(id: @return_authorization.return_reason_id)&.name
      end

      def base_attributes
        @return_authorization.attributes.extract!('number', 'state', 'memo')
      end
    end
  end
end
