class AddUniqueNameIndexToOptionValue < ActiveRecord::Migration[5.2]
  def change

    add_index :spree_option_values, :name, unique: true
  end
end
