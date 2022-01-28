class CreateOrderManagementOrderSummaries < ActiveRecord::Migration[6.0]
  def change
    create_table :order_management_order_summaries do |t|
      t.references :sales_order, foreign_key: { to_table: OrderManagement::SalesOrder.table_name }
      t.string :order_management_ref

      t.timestamps
    end

  end
end
