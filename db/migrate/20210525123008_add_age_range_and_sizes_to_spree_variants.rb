class AddAgeRangeAndSizesToSpreeVariants < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_variants, :age_range, :text
    add_column :spree_variants, :clothing_sizes, :text
    add_column :spree_variants, :shoe_sizes, :text
  end
end
