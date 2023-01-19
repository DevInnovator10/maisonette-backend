class AddRenamedToToSpreeProduct < ActiveRecord::Migration[6.0]
  def change
    add_reference :spree_products, :renamed_to, foreign_key: { to_table: Spree::Product.table_name }
  end
end
