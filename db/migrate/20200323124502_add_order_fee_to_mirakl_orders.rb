class AddOrderFeeToMiraklOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :mirakl_orders, :order_fee, :decimal

  end
end
