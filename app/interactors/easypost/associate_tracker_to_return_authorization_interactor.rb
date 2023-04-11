# frozen_string_literal: true

module Easypost
  class AssociateTrackerToReturnAuthorizationInteractor < ApplicationInteractor
    helper_methods :authorization

    def call
      return unless tracking_number

      register_easypost_tracker(authorization)
    end

    private

    def register_easypost_tracker(authorization)
      context = ::Easypost::CreateTrackerInteractor.call(tracking_code: tracking_number,
                                                         carrier: carrier,
                                                         return_authorization: authorization)
      return if context.tracker.blank?

      create_easypost_tracker(authorization, context.tracker.status)
    end

    def create_easypost_tracker(authorization, status)
      params = { carrier: carrier, tracking_code: tracking_number,
                 spree_return_authorization_id: authorization.id, status: status }
      tracker = Easypost::Tracker.create(params)

      return if tracker.valid?

      Sentry.capture_message(I18n.t('errors.easypost.trackers.unable_to_create'),
                             extra: {
                               carrier: carrier,
                               tracking_code: tracking_number,
                               spree_return_authorization_id: authorization.number,
                               status: status
                             })
    end

    def tracking_number
      authorization.tracking_number
    end

    def carrier
      'UPS'
    end
  end
end
