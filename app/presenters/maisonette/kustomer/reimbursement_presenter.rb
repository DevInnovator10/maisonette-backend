# frozen_string_literal: true

module Maisonette
  module Kustomer
    class ReimbursementPresenter
      def initialize(reimbursement)
        @reimbursement = reimbursement
      end

      def kustomer_payload
        base_attributes.merge(
          'reimbursementStatus' => @reimbursement.reimbursement_status,
          'customerReturnNumber' => customer_return_number
        )
      end

      private

      def base_attributes
        @reimbursement.attributes.extract!('number', 'total')
      end

      def customer_return_number
        @reimbursement.customer_return&.number
      end
    end
  end
end
