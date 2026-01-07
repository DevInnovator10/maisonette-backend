# frozen_string_literal: true

class CreateMaisonetteFees < ActiveRecord::Migration[6.0]
  def change
    create_table :maisonette_fees do |t|
      t.decimal :amount, precision: 10, scale: 2
      t.integer :type
      t.references :spree_return_authorization, index: true
      t.references :spree_reimbursement, index: true

      t.timestamps
    end
  end
end
