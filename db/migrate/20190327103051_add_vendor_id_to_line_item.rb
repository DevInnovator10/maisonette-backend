class AddVendorIdToLineItem < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :vendor_id, :integer
    add_index :spree_line_items, :vendor_id
  end

end
