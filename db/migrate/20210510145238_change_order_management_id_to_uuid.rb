class ChangeOrderManagementIdToUuid < ActiveRecord::Migration[5.2]
  def up
    add_column :order_management_entities, :uuid, :uuid, default: 'gen_random_uuid()', null: false

    change_table :order_management_entities do |t|
      t.remove :id
      t.rename :uuid, :id
    end

    execute 'ALTER TABLE order_management_entities ADD PRIMARY KEY (id);'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
