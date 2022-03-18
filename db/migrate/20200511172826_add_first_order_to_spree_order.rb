class AddFirstOrderToSpreeOrder < ActiveRecord::Migration[5.2]
  def change

    add_column :spree_orders, :first_order, :boolean, default: false
  end
end
