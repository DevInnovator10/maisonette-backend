class AddSkuIndexToMiraklOffers < ActiveRecord::Migration[5.2]
  def change
    add_index :mirakl_offers, :sku
  end
end
