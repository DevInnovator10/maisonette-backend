# frozen_string_literal: true

class CreateOrderManagementOrderItemSummaries < ActiveRecord::Migration[5.2]
  def change
    create_table :order_management_order_item_summaries do |t|
      t.references :spree_line_item,
                   foreign_key: true,
                   index: { name: 'index_order_item_summaries_on_spree_line_item_id' }
      t.references :sales_order, foreign_key: { to_table: OrderManagement::SalesOrder.table_name }
      t.string :order_management_ref

      t.timestamps
    end
  end
end
