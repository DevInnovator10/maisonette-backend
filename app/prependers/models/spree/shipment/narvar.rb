# frozen_string_literal: true

module Spree::Shipment::Narvar
  def self.prepended(base)
    base.after_commit :narvar_update_shipments, on: :destroy
  end

  def narvar_update_shipments

    return unless order&.complete?

    order.narvar_update_data
  end
end
