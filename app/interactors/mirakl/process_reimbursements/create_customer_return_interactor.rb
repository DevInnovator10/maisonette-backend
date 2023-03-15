# frozen_string_literal: true

module Mirakl
    module ProcessReimbursements
    class CreateCustomerReturnInteractor < ApplicationInteractor
      after :recalculate_orders

      helper_methods :reimbursements

      def call
        reimbursements.each do |order_line_reimbursement|
          @order_line_reimbursement = order_line_reimbursement
          next unless order_line_reimbursement.state?(:REFUNDED)
          next if return_authorization.blank? || return_authorization.customer_returns.present?

          create_and_receive_customer_return
          orders << order
        rescue StandardError => e
          rescue_and_capture(e, error_details: order_line_reimbursement.attributes.to_s)
        end
      end

      private

      def create_and_receive_customer_return
        customer_return = create_customer_return

        return_items.each do |return_item|
          return_item.update(customer_return: customer_return,
                             reimbursement: reimbursement,
                             acceptance_status: :accepted)
          return_item.receive
        end
      end

      def create_customer_return
        Spree::CustomerReturn.create!(
          return_items: return_items,
          stock_location: stock_location,
          reimbursements: [reimbursement]
        )
      end

      def recalculate_orders
        orders.uniq.each(&:recalculate)
      end

      def return_items
        return_authorization.return_items
      end

      def stock_location
        return_authorization.stock_location
      end

      def return_authorization
        @order_line_reimbursement.order_line.return_authorization
      end

      def reimbursement
        @order_line_reimbursement.reimbursement
      end

      def order
        @order_line_reimbursement.line_item.order
      end

      def orders
        context.orders ||= []
      end
    end
  end
end
