# frozen_string_literal: true

module Maisonette
  class AssociateCustomerWorker
    include Sidekiq::Worker

    # original method https://github.com/MaisonetteWorld/maisonette-backend/blame/8084a405c1e9cd0b6b47d5eb8cc80a6e0197ca31/app/subscribers/maisonette/associate_customer_subscriber.rb#L9
    def perform(order_id)
      order = fetch_order(order_id)

      return if order.completed_at.nil?

      maisonette_customer = order.user ? customer_for_user(order.user) : customer_by_user_email(order.email)
      maisonette_customer ||= customer_from_guest_order(order.email)
      maisonette_customer ||= Maisonette::Customer.create

      order.update_columns(maisonette_customer_id: maisonette_customer.id) # rubocop:disable Rails/SkipsModelValidations
    end

    private

    def customer_for_user(user)
      user.maisonette_customer
    end

    def customer_by_user_email(email)
      Spree::User.find_by(email: email)&.maisonette_customer
    end

    def customer_from_guest_order(email)
      Maisonette::Customer.joins(:orders).find_by(spree_orders: { email: email, state: :complete })
    end

    def fetch_order(order_id)
      Spree::Order.find(order_id)
    end
  end
end
