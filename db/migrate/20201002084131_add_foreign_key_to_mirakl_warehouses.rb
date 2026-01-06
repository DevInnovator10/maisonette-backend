class AddForeignKeyToMiraklWarehouses < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :mirakl_warehouses, :spree_addresses, column: :address_id

  end
end
