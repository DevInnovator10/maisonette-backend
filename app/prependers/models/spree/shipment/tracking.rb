# frozen_string_literal: true

module Spree::Shipment::Tracking
  def tracking_url
    @tracking_url ||= override_tracking_url ||
                      shipping_method.try(:build_tracking_url, tracking, fetch_carrier_code)
  end

  def easypost_delivery_estimation
    return unless tracking

    tracker = Easypost::Tracker.find_by(tracking_code: tracking)

    return unless tracker&.scanned?

    tracker.est_delivery_date&.strftime('%b %d')
  rescue StandardError => e
    Sentry.capture_exception_with_message e
    nil
  end

  private

  def fetch_carrier_code
    NARVAR_DATA[:carrier_code][shipping_carrier_code] || 'USPS'
  end
end
