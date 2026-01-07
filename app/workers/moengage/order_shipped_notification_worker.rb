# frozen_string_literal: true

module Moengage
  class OrderShippedNotificationWorker
    include Sidekiq::Worker

    def perform(order_id)
      order = Spree::Order.find order_id
      order_shipped_notification = Moengage::Notification::OrderShipped.new

      context = Moengage::PushNotificationInteractor.call!(email: order.email, notification: order_shipped_notification)
      Sentry.capture_message(context.message) if context.failure?
    end
  end
end
