# frozen_string_literal: true

module Spree
    module Admin
    module Salsify

      class MiraklOfferExportJobsController < Spree::Admin::BaseController
        def index
          @mirakl_offer_export_jobs =
            ::Salsify::MiraklOfferExportJob.page(params[:page])
                                           .per(params[:per_page] || Spree::Config[:orders_per_page])
                                           .order(id: :desc)
        end

        def pull_offers_from_salsify_to_mirakl
          ::Salsify::ExportMiraklOffersWorker.new.perform
          flash[:notice] = 'Offers Exported From Salsify To Mirakl.'
          redirect_back(fallback_location: admin_salsify_mirakl_offer_export_jobs_path)
        end

        def re_send_offer_file_to_mirakl
          ::Salsify::MiraklOfferExportJob.find(params[:id]).send_offers_to_mirakl
          flash[:notice] = 'Resent File To Mirakl.'
          redirect_back(fallback_location: admin_salsify_mirakl_offer_export_jobs_path)
        end

        private

        def model_class
          ::Salsify::MiraklOfferExportJob
        end
      end
    end
  end
end
