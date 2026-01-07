class AddViewAllOverrideToSpreeTaxons < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxons, :view_all_url_override, :string
  end
end
