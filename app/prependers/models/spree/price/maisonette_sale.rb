# frozen_string_literal: true

module Spree::Price::MaisonetteSale
  def self.prepended(base)
    base.after_save :update_maisonette_sale
  end

  private

  def update_maisonette_sale
    return if discarded? || offer_settings.nil?

    offer_settings.sale_sku_configurations.each do |sale_sku_configuration|
      ::MaisonetteSale::UpdateOnSaleInteractor.call!(
        sale_sku_configuration: sale_sku_configuration,
        price: self
      )
    end
  end
end
