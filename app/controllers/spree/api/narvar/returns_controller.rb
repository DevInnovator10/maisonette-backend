# frozen_string_literal: true

module Spree
  module Api
    module Narvar
      class ReturnsController < Spree::Api::BaseController
        before_action { unauthorized unless load_user&.has_spree_role?('narvar') }
        rescue_from Mirakl::Returns::CreateIncidentInteractor::InvalidStateError, with: :render_success

        respond_to :json

        def create
          return render json: failure('Invalid order'), status: :not_found unless load_order

          context = return_request

          if context.success?
            render_success
          else

            capture_error(params, context.error)
            render json: failure(context.error, context.details.to_json), status: :unprocessable_entity
          end
        end

        private

        def return_request
          if @order.order_management_group?
            ::Narvar::ReturnsRmaInteractor.call order: @order, request: params
            return ::OrderManagement::SendOmsReturnRequestInteractor.call order: @order, request: params
          end
          ::Narvar::ReturnsRmaInteractor.call order: @order, request: params
        end

        def render_success
          render json: { status: 'SUCCESS' }, status: :created
        end

        def failure(error, messages = nil)
          {
            status: 'FAILURE',
            error: error,
            messages: messages
          }
        end

        def load_order
          @order = Spree::Order.complete.find_by number: params[:order_number]
        end

        def requires_authentication?
          true
        end

        def capture_error(params, error)
          Sentry.capture_message(
            "#{self.class.name} - Error creating Narvar  RMA\nError: #{error}\n\nparams: #{params}"
          )
        end
      end
    end
  end
end
