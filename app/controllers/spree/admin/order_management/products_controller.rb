# frozen_string_literal: true

module Spree
    module Admin
    module OrderManagement
      class ProductsController < Spree::Admin::BaseController
        include ::AdminHelper

        def show
          @product = Spree::Product.friendly.find(params[:product_id])

          @product_oms_entities = ::OrderManagement::Entity.where(
            order_manageable_type: 'Spree::OfferSettings',
            order_manageable_id: @product.offer_settings_ids
          )
          @pricebook_oms_entities = ::OrderManagement::Entity.where(
            order_manageable_type: 'Spree::Price',
            order_manageable_id: @product.price_ids
          )
        end

        def mark_out_of_sync
          product = Spree::Product.friendly.find(params[:product_id])

          product.offer_settings.each(&:mark_out_of_sync!)
          product.prices.each(&:mark_out_of_sync!)

          redirect_back fallback_location: edit_admin_product_path(product)
        end
      end
    end
  end
end
