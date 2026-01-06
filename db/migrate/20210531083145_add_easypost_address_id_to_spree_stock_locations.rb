class AddEasypostAddressIdToSpreeStockLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stock_locations, :easypost_address_id, :string
  end
end
