# frozen_string_literal: true

module Easypost
  class Tracker < Easypost::Base
    validates :tracking_code, presence: true, uniqueness: true
    belongs_to :easypost_order,
               foreign_key: :easypost_order_id,
               class_name: 'Easypost::Order',
               inverse_of: :easypost_trackers,
               optional: true

    belongs_to :spree_return_authorization,
               foreign_key: :spree_return_authorization_id,
               class_name: 'Spree::ReturnAuthorization',
               inverse_of: :easypost_tracker,
               optional: true

    serialize :fees, Array

    STATUSES = %w[unknown
                  pre_transit
                  in_transit
                  out_for_delivery
                  delivered
                  available_for_pickup
                  return_to_sender
                  failure
                  cancelled
                  error].freeze

    SCANNED_STATUSES = %w[
      in_transit
      out_for_delivery
      delivered
      available_for_pickup
      return_to_sender
    ].freeze

    after_save :fire_shipped_event, if: -> { date_shipped_previously_changed? && date_shipped.present? }

    def scanned?
      SCANNED_STATUSES.include? status
    end

    private

    def fire_shipped_event
      Spree::Event.fire('easypost_tracker_shipped', easypost_tracker: self)
    end
  end
end
