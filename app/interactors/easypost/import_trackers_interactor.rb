# frozen_string_literal: true

module Easypost
  class ImportTrackersInteractor < ApplicationInteractor
    SHIPPED_TRANSIT_STATUS = {
      'UPS' => 'origin scan',
      'DHLExpress' => 'shipment picked up',
      'USPS' => 'accepted at usps origin facility'
    }.freeze

    before :validate_context

    def call
      return if Easypost::Tracker.find_by(tracking_code: tracking_code)

      update_tracker if tracking_details.present?
    end

    private

    def validate_context
      context.fail!(message: 'Carrier not recognized') unless SHIPPED_TRANSIT_STATUS.key?(carrier)
    end

    def tracking_code
      @tracking_code ||= easypost_order.tracking_code
    end

    def easypost_order
      @easypost_order ||= context.easypost_order
    end

    def update_tracker
      tracker_hash = { carrier: carrier,
                       easypost_order_id: easypost_order.id }
      tracker_hash.merge!(tracker_dates) if tracker_dates
      easypost_tracker.update!(tracker_hash)
    end

    def carrier
      @carrier ||= easypost_order.rate_carrier
    end

    def tracker_dates
      @tracker_dates ||= return_tracker_dates
    end

    def return_tracker_dates
      delivery_updates = tracking_details.compact.each_with_object({}) do |tracking_detail, tracking_updates|
        detail_time = tracking_detail.datetime
        detail_status, detail_message = tracking_detail.status, tracking_detail.message
        if (detail_message.downcase == SHIPPED_TRANSIT_STATUS[carrier]) && tracking_updates[:date_shipped].nil?
          tracking_updates[:date_shipped] = detail_time
        end
        if (detail_status == 'delivered') && tracking_updates[:date_delivered].nil?
          tracking_updates[:date_delivered] = detail_time
        end
      end
      delivery_updates if delivery_updates[:date_shipped].present?
    end

    def tracking_details
      @tracking_details ||= tracker.tracking_details
    end

    def tracker
      @tracker ||= EasyPost::Tracker.all(start_datetime: '2019-01-17T00:00:00Z', tracking_code: tracking_code)
                                    .trackers.last
    end

    def easypost_tracker
      @easypost_tracker ||= Easypost::Tracker.new(tracking_code: tracking_code)
    end
  end
end
