# frozen_string_literal: true

class AddEmailIndexOnOrder < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_orders, :email
  end
end
