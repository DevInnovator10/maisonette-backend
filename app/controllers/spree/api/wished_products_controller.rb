# frozen_string_literal: true

module Spree
  module Api
    class WishedProductsController < Spree::Api::BaseController
      include MineConcerns

      def index
        authorize! :admin, Spree::WishedProduct
        wished_products = Spree::WishedProduct.includes(wished_product_includes)
                                              .order(created_at: :desc)
                                              .ransack(params[:q])
                                              .result
        @wished_products = paginate(wished_products)
      end

      def mine
        wished_products = current_api_user.wished_products.includes(wished_product_includes).ransack(params[:q]).result
        render :index, locals: { wished_products: paginate(wished_products) }, status: :ok
      end

      def show
        authorize! :show, wished_product
      end

      def create
        params_with_user = wished_product_params.reverse_merge!(wishlist_id: current_api_user&.default_wishlist&.id)
        wished_product = Spree::WishedProduct.new(params_with_user)

        authorize! :crud, wished_product

        if wished_product.save
          render :show, locals: { wished_product: wished_product }, status: :created
        else
          invalid_resource! wished_product
        end
      end

      def update
        authorize! :crud, wished_product

        if wished_product.update(wished_product_params)
          render :show, locals: { wished_product: wished_product }, status: :ok
        else
          invalid_resource! wished_product
        end
      end

      def destroy
        authorize! :crud, wished_product

        wished_product.destroy!
        respond_with wished_product, status: :no_content
      end

      private

      def wished_product
        @wished_product ||= Spree::WishedProduct.find_by(id: params[:id])
      end

      def wished_product_params
        params.require(:wished_product).permit(:wishlist_id, :variant_id, :quantity, :remark)
      end

      def wished_product_includes
        [:variant] if with_variant
      end

      def with_variant
        @with_variant ||= params[:with_variant].presence
      end
    end
  end
end
