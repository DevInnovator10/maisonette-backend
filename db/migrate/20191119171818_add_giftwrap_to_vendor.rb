# frozen_string_literal: true

class AddGiftwrapToVendor < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :giftwrap_service, :boolean
    add_column :spree_vendors, :giftwrap_price, :float
    add_column :spree_vendors, :giftwrap_cost, :float
  end
end
