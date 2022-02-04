class RenameRedirectToOnSpreeProduct < ActiveRecord::Migration[6.0]
  def change
    rename_column :spree_products, :redirect_to_id, :migrated_to_id
  end
end
