# This migration comes from solidus_sale_prices (originally 20170712151926)
class AddDeletedAtToSalePrice < SolidusSupport::Migration[4.2]
  def change
    add_column :spree_sale_prices, :deleted_at, :datetime
    add_index :spree_sale_prices, :deleted_at
  end
end
