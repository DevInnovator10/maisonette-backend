# frozen_string_literal: true

module Spree::Admin::VariantsController::Actions
  def reprocess_mirakl_offer
    Mirakl::ProcessOffersOrganizer.call(skus: @variant.offer_settings.pluck(:maisonette_sku))
    flash[:notice] = "Mirakl Offer for #{@variant.sku} updated"

    redirect_back fallback_location: edit_admin_product_variant_url(@product, @variant)
  end

end
