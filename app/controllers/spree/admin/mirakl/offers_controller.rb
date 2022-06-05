# frozen_string_literal: true

module Spree
  module Admin
    module Mirakl
      class OffersController < Spree::Admin::BaseController
        def index
          params[:q] ||= {}
          @active_search = params[:q]&.values&.any?(&:present?)

          @search = ::Mirakl::Offer.eager_load(:shop).ransack(params[:q])

          collection

          last_offer_update
        end

        def full_import_offers
          ::Mirakl::ImportOffersWorker.perform_async(nil)
          flash[:notice] = 'Mirakl Full Offer Sync Running..'
          redirect_back(fallback_location: admin_mirakl_offers_path)
        end

        def delta_import_offers
          ::Mirakl::ImportOffersWorker.perform_async(params[:delta][:updated_since].presence)
          flash[:notice] = 'Mirakl Delta Offer Sync Running..'
          redirect_back(fallback_location: admin_mirakl_offers_path)
        end

        private

        def collection
          @mirakl_offers = @search.result(distinct: true)
                                  .page(params[:page])
                                  .per(params[:per_page] || Spree::Config[:orders_per_page])
                                  .order(id: :desc)
        end

        def last_offer_update
          @last_offer_update = ::Mirakl::Update.ordered_by_started_at_desc.offer.first&.started_at
        end

        def model_class
          ::Mirakl::Offer
        end
      end
    end
  end
end
