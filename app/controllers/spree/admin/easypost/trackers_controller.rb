# frozen_string_literal: true

module Spree
  module Admin
    module Easypost
      class TrackersController < Spree::Admin::ResourceController
        private

        def collection
          return @collection if @collection

          params[:q] ||= {}
          @search = ::Views::Easypost::Tracker.ransack(params[:q])

          @collection = @search.result(distinct: true)
                               .page(params[:page])
                               .per(params[:per_page] || Spree::Config[:admin_products_per_page])
                               .order(id: :desc)
        end

        def model_class
          ::Easypost::Tracker
        end
      end
    end
  end
end
