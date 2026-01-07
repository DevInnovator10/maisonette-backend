class AddDutyFeesToSpreeLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :duty_fees, :decimal, precision: 8, scale: 2
  end
end
