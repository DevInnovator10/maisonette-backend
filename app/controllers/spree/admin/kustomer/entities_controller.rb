# frozen_string_literal: true

module Spree
    module Admin
    module Kustomer
        class EntitiesController < Spree::Admin::BaseController
        include ::AdminHelper

        def index
          params[:q] ||= {}
          @search = ::Maisonette::Kustomer::Entity.ransack(params[:q])
          @kustomer_entities = @search.result(distinct: true)
                                      .page(params[:page])
                                      .per(params[:per_page] || Spree::Config[:orders_per_page])
                                      .order(id: :desc)
        end

        def show

          @kustomer_entity = ::Maisonette::Kustomer::Entity.find(params[:id])
        end

        def sync
          Maisonette::Kustomer::SyncWorker.perform_async(params[:id])

          redirect_back(fallback_location: admin_kustomer_entities_path)
        end
      end
    end
  end
end
