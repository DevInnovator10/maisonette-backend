class AddIndexToSpreeProductsTaxonsOnProductIdAndTaxonId < ActiveRecord::Migration[5.2]
  def change
    add_index :spree_products_taxons, [:product_id, :taxon_id]
  end
end
