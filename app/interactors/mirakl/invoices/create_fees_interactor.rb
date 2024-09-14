# frozen_string_literal: true

module Mirakl
  module Invoices
    class CreateFeesInteractor < Mirakl::Invoices::BaseInteractor
      before :use_operator_key
      helper_methods :mirakl_orders, :response, :shop_id, :mirakl_shop_id, :mark_down_order_line_reimbs, :doc_groups,
                     :return_fees_line_reimbs

      private

      def invoice_type
        'INVOICE'
      end

      def lines
        transaction_fee_lines +
          compliance_fee_lines +
          return_label_fee_lines +
          mark_down_refund_lines +
          cost_price_fee_lines +
          order_fee_lines +
          incidental_debit_lines +
          return_fee_lines_for_non_invoiced_orders +
          return_fee_lines_for_already_invoiced_orders
      end

      def transaction_fee_lines
        orders_with_transaction_fee = select_orders_with_field(transaction_fee_label)
        invoice_lines(orders_with_transaction_fee, transaction_fee_description, transaction_fee_label)
      end

      def return_label_fee_lines
        orders_with_return_label_fee = select_orders_with_field(return_label_fee_label)
        invoice_lines(orders_with_return_label_fee, return_label_fee_description, return_label_fee_label)
      end

      def compliance_fee_lines
        orders_with_compliance_fee.map do |mirakl_order|
          late_shipping_fee = mirakl_order.fetch_additional_field(late_shipping_fee_label).to_f
          no_stock_fee = mirakl_order.fetch_additional_field(no_stock_fee_label).to_f

          if late_shipping_fee > no_stock_fee
            invoice_line(late_shipping_fee, mirakl_order.logistic_order_id, late_shipping_fee_description)
          else
            invoice_line(no_stock_fee, mirakl_order.logistic_order_id, no_stock_fee_description)
          end
        end
      end

      def orders_with_compliance_fee
        mirakl_orders.select do |order|
          order.fetch_additional_field(late_shipping_fee_label) || order.fetch_additional_field(no_stock_fee_label)
        end
      end

      def mark_down_refund_lines
        context.mark_down_order_line_reimbs.map do |reimb|
          amount = reimb.quantity * reimb.order_line.vendor_mark_down_credit_amount

          invoice_line(amount, reimb.order_line.order.logistic_order_id, mark_down_refund_description)
        end
      end

      def cost_price_fee_lines
        cost_price_fee_orders = select_orders_with_field(cost_price_fee_label)
        invoice_lines(cost_price_fee_orders, cost_price_fee_description, cost_price_fee_label)
      end

      def order_fee_lines
        order_fee_orders = select_orders_with_field(order_fee_label)
        invoice_lines(order_fee_orders, order_fee_description, order_fee_label)
      end

      def incidental_debit_lines
        mirakl_orders_with_incidental_debit = select_orders_with_field(incidental_debit_label)

        mirakl_orders_with_incidental_debit.map do |mirakl_order|
          reason = mirakl_order.fetch_additional_field(incidental_debit_reason_label)&.gsub('-', ' ')
          description = reason || incidental_debit_description

          invoice_line(mirakl_order.fetch_additional_field(incidental_debit_label),
                       mirakl_order.logistic_order_id,
                       description)
        end
      end

      def return_fee_lines_for_non_invoiced_orders
        mirakl_orders_with_return_fee_total = select_orders_with_field(return_fee_total_label)
        mirakl_orders_with_return_fee_total.flat_map do |mirakl_order|
          mirakl_order_lines_with_return_fee = mirakl_order.order_lines.reject { |line| line.return_fee.zero? }
          mirakl_order_lines_with_return_fee.map do |mirakl_order_line|
            invoice_line(mirakl_order_line.return_fee,
                         mirakl_order.logistic_order_id,
                         return_fee_description(mirakl_order_line.mirakl_order_line_id))
          end
        end
      end

      def return_fee_lines_for_already_invoiced_orders
        context.return_fees_line_reimbs.map do |reimb|
          invoice_line(reimb.order_line.return_fee,
                       reimb.order_line.order.logistic_order_id,
                       return_fee_description(reimb.order_line.mirakl_order_line_id))
        end
      end

      def transaction_fee_label
        @transaction_fee_label ||= MIRAKL_DATA[:order][:additional_fields][:transaction_fee_amount]
      end

      def late_shipping_fee_label
        @late_shipping_fee_label ||= MIRAKL_DATA[:order][:additional_fields][:late_shipping_fee]
      end

      def no_stock_fee_label
        @no_stock_fee_label ||= MIRAKL_DATA[:order][:additional_fields][:no_stock_fee]
      end

      def return_label_fee_label
        @return_label_fee_label ||= MIRAKL_DATA[:order][:additional_fields][:return_label_fee]
      end

      def incidental_debit_label
        @incidental_debit_label ||= MIRAKL_DATA[:order][:additional_fields][:incidental_debit]
      end

      def incidental_debit_reason_label
        @incidental_debit_reason_label ||= MIRAKL_DATA[:order][:additional_fields][:incidental_debit_reason]
      end

      def cost_price_fee_label
        @cost_price_fee_label ||= MIRAKL_DATA[:order][:additional_fields][:cost_price_fee]
      end

      def order_fee_label
        @order_fee_label ||= MIRAKL_DATA[:order][:additional_fields][:order_fee]
      end

      def return_fee_total_label
        @return_fee_total_label ||= MIRAKL_DATA[:order][:additional_fields][:return_fee_total]
      end

      def transaction_fee_description
        @transaction_fee_description ||= MIRAKL_DATA[:invoice][:lines][:transaction_fee]
      end

      def late_shipping_fee_description
        @late_shipping_fee_description ||= MIRAKL_DATA[:invoice][:lines][:late_shipping_fee]
      end

      def no_stock_fee_description
        @no_stock_fee_description ||= MIRAKL_DATA[:invoice][:lines][:no_stock_fee]
      end

      def return_label_fee_description
        @return_label_fee_description ||= MIRAKL_DATA[:invoice][:lines][:return_label_fee]
      end

      def mark_down_refund_description
        @mark_down_refund_description ||= MIRAKL_DATA[:invoice][:lines][:mark_down_refund]
      end

      def cost_price_fee_description
        @cost_price_fee_description ||= MIRAKL_DATA[:invoice][:lines][:cost_price_fee]
      end

      def order_fee_description
        @order_fee_description ||= MIRAKL_DATA[:invoice][:lines][:order_fee]
      end

      def incidental_debit_description
        @incidental_debit_description ||= MIRAKL_DATA[:invoice][:lines][:incidental_debit]
      end

      def return_fee_fixed_description
        @return_fee_fixed_description ||= MIRAKL_DATA[:invoice][:lines][:return_fee]
      end

      def return_fee_description(mirakl_order_line_id)
        "#{return_fee_fixed_description} - #{mirakl_order_line_id}"
      end
    end
  end
end
