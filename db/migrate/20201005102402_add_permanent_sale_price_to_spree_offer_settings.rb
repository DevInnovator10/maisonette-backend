class AddPermanentSalePriceToSpreeOfferSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_offer_settings, :permanent_sale_price, :decimal, precision: 8, scale: 2
  end
end
