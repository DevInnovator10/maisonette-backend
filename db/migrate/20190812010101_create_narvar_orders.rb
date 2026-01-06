# frozen_string_literal: true

class CreateNarvarOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :narvar_orders do |t|
      t.integer :spree_order_id
      t.string :state
      t.integer :result_code
      t.text :error_messages
      t.timestamps null: false
    end

    add_index :narvar_orders, :spree_order_id
  end
end
