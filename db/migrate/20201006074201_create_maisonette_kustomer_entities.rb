class CreateMaisonetteKustomerEntities < ActiveRecord::Migration[5.2]
  def change
    create_table :maisonette_kustomer_entities do |t|
      t.references :kustomerable, polymorphic: true, index: { name: 'index_kustomer_entities_kustomerable' }
      t.string :type
      t.integer :sync_status
      t.string :last_request_payload
      t.integer :last_result
      t.string :last_message
      t.string :last_response_body
      t.string :last_response_code

      t.timestamps
    end
  end
end
