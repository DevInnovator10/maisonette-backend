# frozen_string_literal: true

module Spree::Order::Klaviyo
  def self.prepended(base)
    base.after_save :notify_klaviyo_shipped, if: :order_was_shipped, unless: :legacy_order?

    base.state_machine do
      after_transition to: :complete, do: :notify_klaviyo_complete, unless: :legacy_order?
    end
  end

  private

  def notify_klaviyo_complete
    ::Klaviyo::CompletedOrderWorker.perform_async(to_gid.to_s, line_item_gids)
  end

  def notify_klaviyo_shipped
    ::Klaviyo::TrackerWorker.perform_async(to_gid.to_s, 'fulfilled')
  end

  def line_item_gids
    line_items.map(&:to_gid).map(&:to_s)
  end

  def order_was_shipped
    saved_change_to_shipment_state? && shipment_state == 'shipped'
  end
end
