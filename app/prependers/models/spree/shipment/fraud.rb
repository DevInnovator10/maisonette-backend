# frozen_string_literal: true

module Spree::Shipment::Fraud
    def self.prepended(base)
    base.state_machine do
      after_transition to: any, do: :update_forter
    end

  end

  def update_forter
    return unless Flipper.enabled?(:forter_fraud_validation)
    return unless order&.complete?

    Forter::SendOrderStatusUpdateWorker.perform_async(order.number)
  end
end
