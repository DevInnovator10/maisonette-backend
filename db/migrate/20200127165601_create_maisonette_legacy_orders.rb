class CreateMaisonetteLegacyOrders < ActiveRecord::Migration[5.2]
  def change
    create_table(:maisonette_legacy_orders) do |t|
      t.references :user, foreign_key: { to_table: :spree_users }, null: false, index: true
      t.jsonb :data, null: false
      t.string :number, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
