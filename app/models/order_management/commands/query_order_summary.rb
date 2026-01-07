# frozen_string_literal: true

module OrderManagement
  module Commands
    class QueryOrderSummary < OrderManagement::OmsCommand
      protected

      def process!
        result = OrderManagement::FetchOrderSummaryInteractor.call(
          sales_order: sales_order
        )
        raise OrderManagement::OmsCommand::OmsCommandFailure, result.error if result.failure?
      end

      private

      def sales_order
        @sales_order ||= OrderManagement::SalesOrder.find_by!(spree_order_id: data['spree_order_id'])
      end
    end
  end
end
