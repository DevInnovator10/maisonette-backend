class AddOrderManagementRefIndexToOrderManagementSalesOrders < ActiveRecord::Migration[5.2]
  def change
    add_index :order_management_sales_orders, :order_management_ref
  end

end
