# frozen_string_literal: true

module Spree
  module Admin
    module Mirakl
      class OrdersController < Spree::Admin::BaseController
        def index
          params[:q] ||= {}
          @active_search = params[:q]&.values&.any?(&:present?)

          @search = ::Views::Mirakl::Order.ransack(params[:q])

          collection

          last_order_update
        end

        def collection
          @mirakl_orders = @search.result
                                  .page(params[:page])
                                  .per(params[:per_page] || Spree::Config[:orders_per_page])
                                  .order(id: :desc)
        end

        def last_order_update
          @last_order_update = ::Mirakl::Update.ordered_by_started_at_desc
                                               .order_list
                                               .first
                                               &.started_at
        end

        def edit
          @mirakl_order = ::Mirakl::Order.find_by(id: params['id'])
          # TODO: Mirakl Incident Reasons
          # @incident_reasons = Mirakl::IncidentReason.all
        end

        def order_list_sync
          ::Mirakl::ImportOrdersInteractor.call(updated_since: params[:delta][:updated_since].presence,
                                                update_orders: true)

          flash[:notice] = MIRAKL_DATA[:flash_notice][:order][:sync_complete]
          redirect_back(fallback_location: admin_mirakl_orders_path)
        end

        def cancel_order
          begin
            mirakl_order.cancel_order!
            flash[:notice] = MIRAKL_DATA[:flash_notice][:order][:cancelled]
          rescue StandardError => e
            flash[:notice] = e.message
          end
          redirect_back(fallback_location: edit_admin_mirakl_order_path(mirakl_order))
        end

        def recreate_easypost_label
          if can_create_label?
            create_labels
          else
            flash[:notice] = I18n.t('errors.easypost.vendor_manages_own_shipping')
          end

          redirect_back(fallback_location: edit_admin_mirakl_order_path(mirakl_order))
        end

        def fetch_easypost_errors
          easypost_order = ::Mirakl::Easypost::CreateOrderOrganizer.call(mirakl_order: mirakl_order,
                                                                         skip_save: true).easypost_order
          message = easypost_order&.fetch_easypost_errors
          flash[:notice] = message || I18n.t('errors.easypost.unable_to_fetch_errors')

          redirect_back(fallback_location: edit_admin_mirakl_order_path(mirakl_order))
        end

        def send_packing_slip
          begin
            ::Mirakl::OrderStateMachine::WaitingDebitPayment::SendPackingSlipOrganizer.call!(mirakl_order: mirakl_order)
            flash[:notice] = MIRAKL_DATA[:flash_notice][:order][:send_packing_slip]
          rescue StandardError => e
            flash[:notice] = e.message
          end

          redirect_back(fallback_location: edit_admin_mirakl_order_path(mirakl_order))
        end

        def model_class
          ::Mirakl::Order
        end

        private

        def mirakl_order
          @mirakl_order ||= ::Mirakl::Order.find(params[:id])
        end

        def can_create_label?
          !mirakl_order.shipment&.mirakl_shop&.manage_own_shipping?
        end

        def create_labels
          context = ::Mirakl::Easypost::SendLabelsOrganizer.call(mirakl_order: mirakl_order,
                                                                 destroy_easypost_orders: true)
          flash[:notice] = context.easypost_error&.message ||
                           context.error_message ||
                           context.easypost_exception&.message ||
                           MIRAKL_DATA[:flash_notice][:order][:recreate_easypost_label]
        rescue StandardError => e
          flash[:notice] = e.message
        end
      end
    end
  end
end
