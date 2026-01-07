# frozen_string_literal: true

module Maisonette
  module Api
    module OrderManagement
      class CancellationsController < Spree::Api::BaseController
        def create
          authorize! :create, :cancellation

          if cancel_interactor.success?
            render json: { cancel: cancel_interactor.reimbursement }, status: :created
          else
            render json: { error: cancel_interactor.error }, status: :unprocessable_entity
          end
        end

        private

        def cancel_interactor
          @cancel_interactor ||= ::OrderManagement::CreateCancelInteractor.call(
            cancel_params.merge(current_user: current_api_user)
          )
        end

        def cancel_params
          params.require(:cancel)
                .permit(
                  :total,
                  info: [:order_item_summary_id, :label, :quantity],
                  refunds: [:reimbursement_method, :amount, :gift_card_email, :transaction_id, :payment_number,
                            :reason_code]
                )
        end
      end
    end
  end
end
