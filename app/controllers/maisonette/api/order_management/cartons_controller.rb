# frozen_string_literal: true

module Maisonette
  module Api
    module OrderManagement
      class CartonsController < Spree::Api::BaseController
        rescue_from StandardError, with: :error_response
        rescue_from CanCan::AccessDenied, with: :unauthorized

        def create
          authorize! :create, :oms_carton

          interactor.success? ? handle_success(interactor) : handle_failure(interactor)
        end

        def update
          authorize! :update, :oms_carton

          if update_tracking_info_interactor.success?
            render(
              json: {
                carton: update_tracking_info_interactor.carton,
                shipments: update_tracking_info_interactor.shipments
              },
              status: :ok
            )
          else
            render json: { errors: update_tracking_info_interactor.error }, status: 422
          end
        end

        def ship
          authorize! :ship, :oms_carton

          result = ::OrderManagement::ShipCartonInteractor.call(
            external_id: params[:external_id],
            tracking_number: params.require(:carton)[:tracking_number]
          )

          if result.success?
            render json: { carton: result.carton }, status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end

        private

        def handle_success(interactor)
          Rails.logger.info "OMS Carton creation success #{interactor.carton.number}"
          render json: { carton: interactor.carton }, status: :created
        end

        def handle_failure(interactor)
          Rails.logger.error "OMS Carton creation failed with: #{interactor.error}"
          render json: { error: interactor.error }, status: :unprocessable_entity
        end

        def error_response(exception)
          ::Sentry.capture_exception_with_message(exception, message: 'OMS Carton Creation failed')
          render json: { error: exception.message }, status: :unprocessable_entity
        end

        def interactor
          @interactor ||= ::OrderManagement::CreateCartonInteractor.call(
            carton_params.merge(current_user: current_api_user)
          )
        end

        def carton_params
          params.require(:carton)
                .permit(
                  :tracking,
                  :shipping_carrier_code,
                  :external_id,
                  items: [:order_item_summary_ref, :quantity]
                )
        end

        def update_tracking_info_interactor
          @update_tracking_info_interactor ||= ::OrderManagement::UpdateTrackingInfoInteractor.call(tracking_params)
        end

        def tracking_params
          params.permit(:tracking, :shipping_carrier_code, :override_tracking_url)
        end
      end
    end
  end
end
