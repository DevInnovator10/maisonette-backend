class AddProductImportIndexOnSpreeTaxons < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_taxons, :name
    add_index :spree_taxons, [:parent_id, :name, :taxonomy_id]
  end
end
