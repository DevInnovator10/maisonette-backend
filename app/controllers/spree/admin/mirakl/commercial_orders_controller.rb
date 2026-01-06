# frozen_string_literal: true

module Spree
  module Admin
    module Mirakl
      class CommercialOrdersController < Spree::Admin::BaseController
        def index
          params[:q] ||= {}
          @active_search = params[:q]&.values&.any?(&:present?)

          @search = ::Mirakl::CommercialOrder.ransack(params[:q])

          @mirakl_commercial_orders = @search.result(distinct: true)
                                             .page(params[:page])
                                             .per(params[:per_page] || Spree::Config[:orders_per_page])
                                             .order(id: :desc)
        end

        def resend_commercial_order
          commercial_order = ::Mirakl::CommercialOrder.find(params[:id])
          commercial_order.submit(resubmit: true)

          flash[:notice] = if commercial_order.error_message
                             MIRAKL_DATA[:flash_notice][:commercial_order][:submitted_with_errors]

                           else
                             MIRAKL_DATA[:flash_notice][:commercial_order][:submitted_successfully]
                           end
          redirect_back(fallback_location: admin_mirakl_commercial_orders_path)
        end

        def recreate_mirakl_orders
          commercial_order = ::Mirakl::CommercialOrder.find(params[:id]).tap(&:recreate_mirakl_orders)

          flash[:notice] = if commercial_order.error_message
                             MIRAKL_DATA[:flash_notice][:commercial_order][:failed_to_mirakl_orders_with_errors]
                           else
                             MIRAKL_DATA[:flash_notice][:commercial_order][:created_mirakl_orders_successfully]
                           end
          redirect_back(fallback_location: admin_mirakl_commercial_orders_path)
        end
      end
    end
  end
end
