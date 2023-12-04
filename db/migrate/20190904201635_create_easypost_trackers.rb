class CreateEasypostTrackers < ActiveRecord::Migration[5.2]

  def change
    create_table :easypost_trackers do |t|
      t.belongs_to :easypost_order, index: true, foreign_key: true

      t.text :webhook_payload
      t.string :tracking_code, index: true, unique: true
      t.string :carrier, index: true
      t.timestamp :date_shipped
      t.timestamp :date_delivered

      t.timestamps null:false
    end
  end
end
