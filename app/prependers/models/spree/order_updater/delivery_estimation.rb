# frozen_string_literal: true

module Spree::OrderUpdater::DeliveryEstimation
  private

  def update_shipment_amounts
    shipments.each { |shipment| shipment.delivery_estimation = Spree::DeliveryTimeCalculator.new(shipment).to_s }

    super
  end
end
