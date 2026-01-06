class CreateMiraklUpdates < ActiveRecord::Migration[5.2]
    def change
    create_table :mirakl_updates do |t|
      t.integer :mirakl_type
      t.datetime :started_at, index: {order: {started_at: :desc}}

      t.timestamps
    end
  end
end
