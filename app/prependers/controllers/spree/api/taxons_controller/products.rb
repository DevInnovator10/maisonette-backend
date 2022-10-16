# frozen_string_literal: true

module Spree::Api::TaxonsController::Products
  def products
    taxon = if params[:permalink].present?
              Spree::Taxon.find_by!(permalink: params[:permalink])
            else
              Spree::Taxon.find(params[:id])
            end
    @products = paginate(taxon.products.ransack(params[:q]).result)
    @products = @products.includes(master: :default_price)

    if params[:simple]
      @exclude_data = { variants: true, option_types: true, product_properties: true, classifications: true }
      @product_attributes = %i[id name display_price]
    end

    render 'spree/api/products/index'
  end
end
