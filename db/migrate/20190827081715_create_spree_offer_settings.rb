class CreateSpreeOfferSettings < ActiveRecord::Migration[5.2]
  def up
    create_table :spree_offer_settings do |t|
      t.references :variant, foreign_key: { to_table: :spree_variants }, null: false, index: false
      t.references :vendor, foreign_key: { to_table: :spree_vendors }, null: false, index: false

      t.boolean :monogrammable_only, null: false, default: false
      t.decimal :monogram_price, precision: 8, scale: 2
      t.decimal :monogram_cost_price, precision: 8, scale: 2
      t.integer :monogram_lead_time
      t.integer :monogram_max_characters
      t.jsonb :monogram_customizations

      t.datetime :discarded_at

      t.timestamps

      t.index :discarded_at
      t.index [:variant_id, :vendor_id], unique: true, where: 'discarded_at IS NULL'
    end
  end

  def down
    drop_table :spree_offer_settings
  end
end
