class CreateOrderManagementCancellationReasons < ActiveRecord::Migration[6.0]
  def up
    create_table :order_management_cancellation_reasons do |t|
      t.string :name, null: false
      t.boolean :active, default: true
      t.string :code, null: false
      t.boolean :mutable, default: true
      t.string :mirakl_code

      t.timestamps
    end
  end

  def down
    drop_table :order_management_cancellation_reasons
  end
end
