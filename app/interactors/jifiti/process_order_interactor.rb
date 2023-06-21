# frozen_string_literal: true

module Jifiti
    class ProcessOrderInteractor < ApplicationInteractor
    before :prepare_order_params

    def call
      order = Spree::Order.create order_params
      order.next! # to address
      order.bill_address = order.ship_address
      order.next! # to delivery
      order.next! # to payment
      order.payments.create(payment_method: Spree::PaymentMethod.jifiti, amount: order.total, state: :checkout)
      order.next! # to confirm
      order.payments.each { |payment| payment.state = :completed }
      order.complete! # to complete

      context.order = order
    end

    private

    def prepare_order_params
      order_params.merge! channel: 'jifiti'
      order_params[:line_items_attributes].each do |li_attributes|
        vendor_name = li_attributes.delete(:vendor_name)
        li_attributes[:vendor_id] = Spree::Vendor.find_by(name: vendor_name).id
      end
    end

    def order_params
      context.order_params
    end
  end
end
