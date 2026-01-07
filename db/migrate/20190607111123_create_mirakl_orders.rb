class CreateMiraklOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :mirakl_orders do |t|
      t.string :state
      t.string :logistic_order_id
      t.references :commercial_order
      t.references :shipment
      t.float :late_shipping_fee, default: 0.0
      t.float :no_stock_fee, default: 0.0
      t.float :return_label_fee
      t.boolean :invoiced, default: false
      t.boolean :incident, default: false
      t.datetime :invoicing_date
      t.jsonb :mirakl_payload, default: {}

      t.timestamps
    end
  end
end
