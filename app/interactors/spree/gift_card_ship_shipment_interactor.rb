# frozen_string_literal: true

module Spree
  class GiftCardShipShipmentInteractor < ApplicationInteractor
    def call
      shipment.ship if shipment.line_items.all? { |li| li.gift_cards.all?(&:sent_at) }
    rescue StandardError => e
      rescue_and_capture(e)
    end

    private

    def shipment
      @shipment ||= context.gift_card.line_item.inventory_units[0].shipment
    end
  end
end
