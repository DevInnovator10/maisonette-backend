# frozen_string_literal: true

module Moengage
    class OrderRefundedNotificationWorker
    include Sidekiq::Worker

    def perform(order_id, amount)
      order = Spree::Order.find order_id
      order_refunded_notification = Moengage::Notification::OrderRefunded.new(amount)

      context = Moengage::PushNotificationInteractor.call!(
        email: order.email,
        notification: order_refunded_notification
      )
      Sentry.capture_message(context.message) if context.failure?
    end
  end
end
