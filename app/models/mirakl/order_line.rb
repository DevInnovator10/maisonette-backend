# frozen_string_literal: true

module Mirakl
  class OrderLine < Mirakl::Base
    belongs_to :order, optional: false
    belongs_to :line_item, class_name: 'Spree::LineItem', optional: false
    belongs_to :return_authorization, class_name: 'Spree::ReturnAuthorization', optional: true
    has_many :order_line_reimbursements, dependent: :destroy, class_name: 'Mirakl::OrderLineReimbursement'

    include Mirakl::OrderLine::StateMachine

    scope :no_stock_cancellation, lambda {
      joins(order_line_reimbursements: :refund_reason)
        .where(spree_refund_reasons: { name: MIRAKL_DATA[:cancellation_reason][:no_stock] })
    }
    scope :refused, -> { where(state: :REFUSED) }
    scope :not_canceled, -> { where.not(state: [:REFUSED, :CANCELED]) }

    scope :with_order_line_reimbursements, -> { joins(:order_line_reimbursements).distinct }
    scope :has_marked_down_prices, -> { where.not(vendor_mark_down_credit_total: nil) }
    scope :has_cost_price_total, -> { where.not(cost_price_fee_total: nil) }

    def self.part_of_return_authorization(return_authorization)
      joins(line_item: [inventory_units: [return_items: :return_authorization]])
        .where(spree_return_authorizations: { id: return_authorization })
        .distinct
    end

    def process_update!(order_line_payload)
      new_state = order_line_payload['order_line_state']
      order_line_state_event = "#{new_state.downcase}!"
      old_state = state

      if old_state != new_state && respond_to?(order_line_state_event) && STATES.include?(new_state)
        send(order_line_state_event)
      end
      process_reimbursement(order_line_payload, old_state, new_state)
    end

    def process_reimbursement(order_line_payload, old_state, new_state)
      if line_item.order.order_management_group?
        process_oms_reimbursement(old_state, new_state)
      else
        Mirakl::ProcessReimbursementsOrganizer.call(mirakl_order: order,
                                                    mirakl_order_line: self,
                                                    order_line_payload: order_line_payload)
      end
    end

    def process_oms_reimbursement(old_state, new_state)
      refund = new_refund_from_mirakl
      return if new_state != 'SHIPPED' || old_state != 'INCIDENT_OPEN' || refund.nil?

      OrderManagement::PostReturnItemReceivedInteractor.call(mirakl_order_line: self,
                                                             order_line_payload: mirakl_order_line_payload,
                                                             refund: refund)
    end

    def mirakl_order_line_payload
      order.mirakl_payload['order_lines'].detect { |ol| ol['order_line_id'] == mirakl_order_line_id }
    end

    def new_refund_from_mirakl
      mirakl_order_line_payload['refunds'].detect { |refund| refund['state'] == 'WAITING_REFUND_PAYMENT' }
    end

    def price_unit
      mirakl_order_line_payload['price_unit']
    end

    def quantity
      mirakl_order_line_payload['quantity']
    end

    def subtotal
      mirakl_order_line_payload['price']
    end

    def shipping_cost
      mirakl_order_line_payload['shipping_price']
    end

    def tax_amount
      mirakl_order_line_payload['taxes'].map { |tax| tax['amount'] }.sum
    end

    def total_tax_amount(taxes)
      taxes.sum { |tax| tax['amount'] }
    end

    def total
      mirakl_order_line_payload['total_price']
    end

    def incidentable?
      %w[SHIPPING SHIPPED].include? state
    end
  end
end
