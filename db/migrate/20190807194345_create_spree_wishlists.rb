# frozen_string_literal: true

class CreateSpreeWishlists < ActiveRecord::Migration[5.2]
    def change
    create_table :spree_wishlists do |t|
      t.references :user
      t.string :name
      t.string :access_hash
      t.boolean :is_public, default: false, null: false
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end
  end
end
