class CreateMiraklCommercialOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :mirakl_commercial_orders do |t|
      t.references :spree_order, index: true
      t.string :commercial_order_id
      t.string :state
      t.string :error_message

      t.timestamps

    end
  end
end
