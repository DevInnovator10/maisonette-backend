# frozen_string_literal: true

class AddAvalaraCodeToVendor < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :avalara_code, :string

    add_index :spree_vendors, :avalara_code, unique: true
  end
end
