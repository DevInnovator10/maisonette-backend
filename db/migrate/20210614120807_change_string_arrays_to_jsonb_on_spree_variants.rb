class ChangeStringArraysToJsonbOnSpreeVariants < ActiveRecord::Migration[5.2]
  def up
    remove_column :spree_variants, :age_range
    remove_column :spree_variants, :clothing_sizes
    remove_column :spree_variants, :shoe_sizes

    add_column :spree_variants, :age_range, :jsonb
    add_column :spree_variants, :clothing_sizes, :jsonb
    add_column :spree_variants, :shoe_sizes, :jsonb
  end

  def down
    remove_column :spree_variants, :age_range
    remove_column :spree_variants, :clothing_sizes
    remove_column :spree_variants, :shoe_sizes

    add_column :spree_variants, :age_range, :text
    add_column :spree_variants, :clothing_sizes, :text
    add_column :spree_variants, :shoe_sizes, :text
  end
end
