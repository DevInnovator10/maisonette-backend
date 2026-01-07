class CreateEasypostShipments < ActiveRecord::Migration[5.2]
    def change
    create_table :easypost_shipments do |t|
      t.belongs_to :easypost_order, index: true
      t.belongs_to :easypost_parcel, index: true

      t.timestamps null: false
    end
  end
end
