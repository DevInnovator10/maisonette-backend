# frozen_string_literal: true

module Spree::Admin::ProductsController::Actions
  def reprocess_mirakl_offer
    Mirakl::ProcessOffersOrganizer.call(skus: skus_to_update)
    flash[:notice] = "Mirakl Offer for #{skus_to_update} updated"

    redirect_back fallback_location: admin_product_variants_url(@product)
  end

  private

  def skus_to_update
    Spree::OfferSettings.where(variant: @product.variants).pluck(:maisonette_sku)
  end
end
