# frozen_string_literal: true

module Maisonette
    module Api
    module OrderManagement
      class AppeasementsController < Spree::Api::BaseController
        def create
          authorize! :create, :appeasement

          if appeasement_interactor.success?
            render json: { appeasement: appeasement_interactor.reimbursement }, status: :created
          else
            render json: { error: appeasement_interactor.error }, status: :unprocessable_entity
          end
        end

        private

        def appeasement_interactor
          @appeasement_interactor ||= ::OrderManagement::CreateAppeasementInteractor.call(
            appeasement_params.merge(current_user: current_api_user)
          )
        end

        def appeasement_params
          params.require(:appeasement)
                .permit(
                  :total,
                  info: [:order_item_summary_id, :label, :amount, :adjustment_reason_external_id],
                  refunds: [:reimbursement_method, :amount, :gift_card_email, :transaction_id, :payment_number,
                            :reason_code]
                )
        end
      end
    end
  end
end
