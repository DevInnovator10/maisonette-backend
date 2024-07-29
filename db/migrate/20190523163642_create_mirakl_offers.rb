class CreateMiraklOffers < ActiveRecord::Migration[5.2]
  def change
    create_table :mirakl_offers do |t|
      t.integer :offer_id, null: false, index: true
      t.integer :shop_id, null: false, index: true
      t.integer :quantity
      t.string :sku
      t.string :offer_state
      t.boolean :active
      t.boolean :best, default: false, null: false

      t.decimal :original_price
      t.decimal :price
      t.datetime :available_to
      t.datetime :available_from

      t.timestamps
    end
  end
end
