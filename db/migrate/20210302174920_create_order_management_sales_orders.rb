# frozen_string_literal: true

class CreateOrderManagementSalesOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :order_management_sales_orders do |t|
      t.references :spree_order, foreign_key: true
      t.string :order_management_ref

      t.timestamps
    end
  end
end
