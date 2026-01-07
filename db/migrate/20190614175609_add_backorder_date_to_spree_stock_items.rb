# frozen_string_literal: true

class AddBackorderDateToSpreeStockItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stock_items, :backorder_date, :datetime
  end
end
