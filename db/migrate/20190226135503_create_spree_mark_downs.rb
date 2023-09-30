# frozen_string_literal: true

class CreateSpreeMarkDowns < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_mark_downs do |t|
      t.string :title
      t.decimal :amount
      t.boolean :final_sale
      t.decimal :our_liability
      t.decimal :vendor_liability
      t.boolean :active
      t.datetime :start_at
      t.datetime :end_at

      t.timestamps
    end
  end
end
