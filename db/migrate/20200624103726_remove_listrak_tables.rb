class RemoveListrakTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :listrak_export_customers_jobs
    drop_table :listrak_export_orders_jobs
  end

  def down
    create_table :listrak_export_customers_jobs do |t|
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    create_table :listrak_export_orders_jobs do |t|
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
