# frozen_string_literal: true

module Spree
  module Admin
    module Mirakl
      class ProductsController < Spree::Admin::BaseController
        def upload_deleted_products
          context = ::Mirakl::DeleteProductsInteractor.call(products_file: params[:delete_products_file])

          if context.success?
            flash[:success] = "Successfully uploaded the products file. Synchro ID: #{context.synchro_id}"
            redirect_to(admin_mirakl_delete_products_path)
          else
            flash.now[:error] = context.message
            render :delete_products
          end
        end

        private

        def authorize_admin
          authorize! :destroy, :mirakl_products
        end
      end
    end
  end
end
