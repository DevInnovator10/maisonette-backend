# frozen_string_literal: true

module Spree::Payment::Fraud
  def self.prepended(base)
    base.state_machine do
      after_transition to: [:failed], do: :update_forter
    end
  end

  def update_forter
    return unless Flipper.enabled?(:forter_fraud_validation)

    Forter::SendOrderStatusUpdateWorker.perform_async(order.number, id)
  end
end
