# frozen_string_literal: true

module Easypost
  class CreateTrackerInteractor < ApplicationInteractor
    helper_methods :tracking_code, :carrier, :mirakl_order, :return_authorization

    def call
      return unless tracking_code

      context.tracker = ::EasyPost::Tracker.create(tracking_code: tracking_code, carrier: carrier)
    rescue EasyPost::Error => e
      return if ignorable_exception?(e.message)

      create_without_carrier(e)
    rescue StandardError => e
      capture_unable_to_create_exception(e)
    end

    private

    def ignorable_exception?(message)
      message.include? EASYPOST_DATA[:ignore_codes][:in_flight_request]
    end

    def create_without_carrier(previous_exception)
      context.tracker = ::EasyPost::Tracker.create(tracking_code: tracking_code)

      extra = { tracking_code: tracking_code,
                incorrect_carrier: carrier,
                actual_carrier: context.tracker.carrier,
                mirakl_order: mirakl_order&.logistic_order_id,
                previous_exception: previous_exception.message }
      log_event(:info, "#{I18n.t('errors.easypost.trackers.created_with_only_tracking_code')}\n#{extra}")
    rescue StandardError => e
      capture_unable_to_create_exception(e, previous_exception: previous_exception.message)
    end

    def capture_unable_to_create_exception(exception, previous_exception: nil)
      message_key = return_authorization ? 'unable_to_create_return' : 'unable_to_create'
      Sentry.capture_exception_with_message(exception,
                                            message: I18n.t("errors.easypost.trackers.#{message_key}"),
                                            extra: { tracking_code: tracking_code,
                                                     carrier: carrier,
                                                     mirakl_order: mirakl_order&.logistic_order_id,
                                                     return_authorization: return_authorization&.number,
                                                     previous_exception: previous_exception })

      return if mirakl_order.blank?

      send_operator_message
    end

    def send_operator_message
      Mirakl::SendOperatorMessageToOrderInteractor.call(mirakl_order_id: mirakl_order.logistic_order_id,
                                                        message: mirakl_vendor_message,
                                                        subject: mirakl_vendor_subject,
                                                        to_shop: true)
    end

    def mirakl_vendor_message
      I18n.t('mirakl.shipping_tracker_error_message', tracking_info: "#{tracking_code} - #{carrier}")
    end

    def mirakl_vendor_subject
      I18n.t('mirakl.shipping_tracker_message_subject')
    end
  end
end
