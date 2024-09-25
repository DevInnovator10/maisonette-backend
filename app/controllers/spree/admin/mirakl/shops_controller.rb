# frozen_string_literal: true

module Spree
  module Admin
    module Mirakl
      class ShopsController < Spree::Admin::BaseController
        def index
          params[:q] ||= {}

          @search = ::Mirakl::Shop.eager_load(:stock_location).ransack(params[:q])

          @mirakl_shops = @search.result(distinct: true)
                                 .page(params[:page])
                                 .per(params[:per_page] || Spree::Config[:orders_per_page])
                                 .order(id: :desc)
        end

        def import_shops
          ::Mirakl::ImportShopsInteractor.call
          redirect_back(fallback_location: admin_mirakl_shops_path)
        end

        def model_class
          ::Mirakl::Shop
        end
      end
    end
  end
end
