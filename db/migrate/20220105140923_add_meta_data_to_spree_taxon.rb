class AddMetaDataToSpreeTaxon < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_taxons, :meta_data, :jsonb, default: {}
  end
end
