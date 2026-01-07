class AddUniquenessConstraintToSpreeOptionValues < ActiveRecord::Migration[5.2]
  def up
    remove_index :spree_option_values, :name # to remove unique: true from index
    add_index :spree_option_values, :name

    add_index :spree_option_values, [:name, :option_type_id], unique: true
  end

  def down
    add_index :spree_option_vaules, :name, unique: true
    remove_index :spree_option_values, [:name, :option_type_id]
  end
end
