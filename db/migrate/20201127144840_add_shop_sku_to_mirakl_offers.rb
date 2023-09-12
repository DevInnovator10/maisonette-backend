class AddShopSkuToMiraklOffers < ActiveRecord::Migration[5.2]
  def change
    add_column :mirakl_offers, :shop_sku, :string
  end
end
