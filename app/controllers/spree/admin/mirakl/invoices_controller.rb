# frozen_string_literal: true

module Spree
  module Admin
    module Mirakl
      class InvoicesController < Spree::Admin::BaseController
        def index
          params[:q] ||= {}
          @active_search = params[:q].values.any?(&:present?)

          @search = ::Mirakl::Invoice.eager_load(:mirakl_shop).ransack(params[:q])
          @mirakl_invoices = @search.result(distinct: true)
                                    .page(params[:page])
                                    .per(params[:per_page] || Spree::Config[:orders_per_page])
                                    .order(id: :desc)
        end

        def issue_all_invoices
          ::Mirakl::IssueInvoicesWorker.perform_async
          flash[:notice] = MIRAKL_DATA[:flash_notice][:invoice][:issuing]
          redirect_back(fallback_location: admin_mirakl_invoices_path)
        end
      end
    end
  end
end
