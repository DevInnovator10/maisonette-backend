class AddShippingCarriersToMiraklShops < ActiveRecord::Migration[5.2]

  def change
    add_column :mirakl_shops, :shipping_carriers, :text
  end
end
