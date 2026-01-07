class AddSpreeMarkDownsTaxons < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_mark_downs_taxons do |t|
      t.integer :mark_down_id
      t.integer :taxon_id
      t.boolean :exclude, default: false
    end

    add_index :spree_mark_downs_taxons, :mark_down_id
    add_index :spree_mark_downs_taxons, :taxon_id
  end
end