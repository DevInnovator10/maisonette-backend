# frozen_string_literal: true

class CreateSalsifyImportRows < ActiveRecord::Migration[5.2]
  def change
    create_table :salsify_import_rows do |t|
      t.references :salsify_import, foreign_key: { to_table: 'salsify_imports' }
      t.references :spree_product, foreign_key: { to_table: 'spree_products' }
      t.text :data
      t.text :messages
      t.string :state, null: false, default: 'created'
      t.timestamps null: false
    end
  end
end
