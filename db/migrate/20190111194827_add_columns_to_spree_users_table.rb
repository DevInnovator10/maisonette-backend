# frozen_string_literal: true

class AddColumnsToSpreeUsersTable < ActiveRecord::Migration[5.2]
    def change
    change_table :spree_users, bulk: true do |t|
      t.string :first_name
      t.string :last_name

      t.boolean :receive_emails_agree, default: false

      t.string :exemption_number
      t.string :vat_id
      t.integer :avalara_entity_use_code_id

      t.string :default_payment_method_token

      t.index :bill_address_id, using: :btree
      t.index :ship_address_id, using: :btree
    end
  end

end
