# frozen_string_literal: true

module Maisonette
  module Api
    module OrderManagement
      class CustomerReturnsController < Spree::Api::BaseController
        def create
          authorize! :create, :oms_return

          if customer_return_interactor.success?
            render json: { success: true }, status: :created
          else
            render json: { error: customer_return_interactor.error }, status: :unprocessable_entity

          end
        end

        private

        def customer_return_interactor
          @customer_return_interactor ||=
            ::OrderManagement::CreateCustomerReturnInteractor.call(
              permitted_params.merge(current_user: current_api_user)
            )
        end

        def permitted_params
          params.require(:return).permit(:mirakl_order_line_id, :mirakl_reimbursement_id, :total, refunds:
            [:reimbursement_method,
             :amount,
             :payment_number,
             :transaction_id,
             :gift_card_email,
             :notes,
             :reason_code])
        end
      end
    end
  end
end
