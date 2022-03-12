# frozen_string_literal: true

module Spree::Order::OrderManagement
  def self.prepended(base)
    base.has_one :sales_order,
                 class_name: 'OrderManagement::SalesOrder',
                 foreign_key: :spree_order_id
    base.include Maisonette::Flipper::Identifier
    base.extend ClassMethods
    alias payload_for_oms_csv historical_oms_payload
  end

  module ClassMethods
    def ransackable_scopes(_auth_object = nil)
      %i[forward_status]
    end

    def forward_status(status) # rubocop:disable Metrics/MethodLength
      case status
      when 'failed'
        complete.joins(:sales_order).where(order_management_sales_orders: { order_management_ref: nil })
                .where.not(order_management_sales_orders: { last_request_payload: nil })
      when 'error'
        complete.left_outer_joins(:sales_order).where(order_management_sales_orders: { spree_order_id: nil })
      when 'pending'
        complete.joins(:sales_order).where(order_management_sales_orders: {
                                             last_request_payload: nil, order_management_ref: nil
                                           })
      when 'forwarded'
        complete.joins(:sales_order).where.not(order_management_sales_orders: { order_management_ref: nil })
      end
    end
  end

  def order_management_group?
    return user.has_spree_role?(:oms_backend) if user.present?

    email&.include?('oms.test')
  end

  def send_to_order_management?
    Flipper.enabled? :oms_place_order, self
  end

  def forwarded?
    return unless sales_order

    sales_order.order_management_ref.present? && sales_order.last_request_payload.present?
  end

  def historical_oms_payload
    ::OrderManagement::HistoricalOrderPresenter.new(self).payload
  end
end
