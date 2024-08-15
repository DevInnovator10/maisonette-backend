# frozen_string_literal: true

module OrderManagement
    class ShipCartonInteractor < ApplicationInteractor
    required_params :external_id, :tracking_number
    helper_methods :external_id, :tracking_number

    before :validate_context

    def call
      carton.ship!
    end

    private

    def validate_context
      context.fail!(error: "External ID required in #{self.class.name}") if external_id.blank?
      context.fail!(error: "Tracking number required in #{self.class.name}") if tracking_number.blank?
    end

    def mirakl_order
      @mirakl_order ||= GlobalID::Locator.locate(external_id).tap do |mirakl_order|
        if mirakl_order.nil? || !mirakl_order.is_a?(::Mirakl::Order)
          context.fail!(error: "Invalid external ID in #{self.class.name}")
        end
      end
    end

    def carton
      context.carton ||= mirakl_order.shipment.cartons.find_by(tracking: tracking_number).tap do |carton|
        context.fail!(error: "Invalid tracking number in #{self.class.name}") if carton.nil?
      end
    end
  end
end
