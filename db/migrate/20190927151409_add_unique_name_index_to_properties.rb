class AddUniqueNameIndexToProperties < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_properties, :name, unique: true
  end
end
