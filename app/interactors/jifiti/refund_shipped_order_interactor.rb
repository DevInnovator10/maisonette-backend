# frozen_string_literal: true

module Jifiti
    class RefundShippedOrderInteractor < ApplicationInteractor
    before :validate_context

    def call
      create_store_credit(receiver_user, context.amount)
    rescue StandardError => e
      Sentry.capture_exception_with_message(e)
      RefundMailer.error_refund_shipped_order(order)
    end

    private

    def create_store_credit(user, amount)
      Spree::StoreCredit.create!(
        user: user,
        amount: amount,
        created_by: jifiti_admin_user,
        memo: "Store credit for refund order #{order.number}",
        currency: 'USD',
        category: Spree::StoreCreditCategory.find_by(name: 'Item Refund'),
        credit_type: Spree::StoreCreditType.find_by(name: 'Non-expiring')
      )
    end

    def jifiti_order
      @jifiti_order ||= Jifiti::OrderPresenter.new(order)
    end

    def jifiti_admin_user
      @jifiti_admin_user ||= Spree::User.find_by(email: Maisonette::Config.fetch('jifiti.admin_user'))
    end

    def order
      @order ||= context.order
    end

    def receiver_user
      @receiver_user ||= Spree::User.find_by(email: jifiti_order.receiver_email)
    end

    def validate_context
      context.fail!(error: 'Order is missing') unless context.order.is_a? Spree::Order
      context.fail!(error: 'Order does not have jifiti information') unless jifiti_order.jifiti?
    end
  end
end
