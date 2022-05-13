# frozen_string_literal: true

module OrderManagement
  class ReturnedItemPresenter
    def initialize(mirakl_order_line_id, reason, order_line_payload, mirakl_reimbursement_id)
      @mirakl_order_line_id = mirakl_order_line_id
      @reason = reason
      @order_line_payload = order_line_payload
      @mirakl_reimbursement_id = mirakl_reimbursement_id
    end

    def quantity
      @order_line_payload['quantity']
    end

    def tax_amount
      @order_line_payload['taxes'].map { |tax| tax['amount'] }.sum
    end

    def total
      @order_line_payload['total_price']
    end

    def payload
      {
        'returnItems':
          [{
            'miraklItemId': @mirakl_order_line_id,
            'reasonExternalId': @reason.order_management_entity.external_id,
            'quantity': quantity,

            'returnAmount': total,
            'returnTaxAmount': tax_amount,
            'mirakl_reimbursement_id': @mirakl_reimbursement_id
          }]
      }
    end
  end
end
