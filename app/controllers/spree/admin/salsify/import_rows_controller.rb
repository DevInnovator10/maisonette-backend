# frozen_string_literal: true

module Spree
  module Admin
    module Salsify
      class ImportRowsController < Spree::Admin::BaseController
        rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }

        def show
          @import_row = ::Salsify::ImportRow.find_by!(salsify_import_id: params[:import_id], id: params[:id])
          @import_row_data = @import_row.data
        end

        def re_process
          @import_row = ::Salsify::ImportRow.products.find_by!(
            salsify_import_id: params[:import_id],
            id: params[:id],
            state: :failed
          )

          ::Salsify::ImportRowWorker.perform_async(@import_row.unique_key, [@import_row.id])

          flash[:success] = I18n.t('spree.admin.salsify.re_process_info')
          redirect_back(fallback_location: admin_salsify_import_import_row_path(
            import_id: @import_row.import.id,
            id: @import_row.id
          ))
        end

        private

        def model_class
          ::Salsify::ImportRow
        end
      end
    end
  end
end
