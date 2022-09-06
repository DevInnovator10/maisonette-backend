# frozen_string_literal: true

module Spree::Order::RestartCheckoutFlow
  class RestartCheckoutFlowInfo < StandardError; end

  def restart_checkout_flow
    return super unless state == 'complete'

    capture_exception
    :restart_failed
  end

  private

  def capture_exception
    message = <<~MESSAGE
      Order Number: #{number}
      Order State: #{state}
      Payment State: #{payment_state}
      Line Items: #{line_items.count}"
    MESSAGE
    exception = RestartCheckoutFlowInfo.new(message)
    exception.set_backtrace(caller)

    Sentry.capture_exception_with_message(exception)
  end
end
