class CreateOrderManagementEntities < ActiveRecord::Migration[5.2]
  def change
    create_table :order_management_entities do |t|
      t.string :order_manageable_type
      t.string :order_manageable_id
      t.string :type
      t.string :order_management_entity_ref
      t.integer :sync_status, default: 1, null: false
      t.integer :last_result
      t.string :last_request_payload
      t.string :last_message
      t.string :last_response_code
      t.index ["order_manageable_type", "order_manageable_id"], name: "index_order_management_entities_order_manageable"
      t.timestamps
    end
  end
end
