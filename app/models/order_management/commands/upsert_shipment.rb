# frozen_string_literal: true

module OrderManagement
  module Commands
    class UpsertShipment < OrderManagement::OmsCommand
      protected

      def process!
        result = OrderManagement::UpsertShipmentInteractor.call(
          mirakl_order: mirakl_order,
          status: data['status']
        )
        raise OrderManagement::OmsCommand::OmsCommandFailure.new(result.error, result.payload) if result.failure?
      end

      private

      def mirakl_order
        @mirakl_order ||= Mirakl::Order.find(data['mirakl_order_id'])
      end
    end
  end
end
