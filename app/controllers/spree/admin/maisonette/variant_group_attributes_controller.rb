# frozen_string_literal: true

module Spree
  module Admin
    module Maisonette
      class VariantGroupAttributesController < Spree::Admin::ResourceController
        belongs_to 'spree/product', find_by: :slug

        before_action :check_feature_enabled

        def index
          @variant_group_attributes = @product.maisonette_variant_group_attributes
                                              .page(params[:page])
                                              .per(Spree::Config.admin_variants_per_page)
        end

        def controller_name
          object_name
        end

        private

        def model_class
          ::Maisonette::VariantGroupAttributes
        end

        def object_name
          'maisonette_variant_group_attributes'
        end

        def location_after_save
          admin_product_variant_group_attributes_path(@product)
        end

        def check_feature_enabled
          return if Flipper.enabled?(:pdp_variant, @product&.salsify_import_rows&.last)

          redirect_back(fallback_location: admin_path, notice: 'Access not allowed')
        end
      end
    end
  end
end
