# frozen_string_literal: true

module Spree::Order::Fraud
  def finalize!
    super

    update_forter
  end

  private

  def update_forter
    return unless Flipper.enabled?(:forter_fraud_validation)

    Forter::SendOrderStatusUpdateWorker.perform_async(number)
  end
end
