class ChangeSyndicationProductsIntegersToBigint < ActiveRecord::Migration[5.2]
  def change
    Syndication::Product.connection.change_column :syndication_products, :inventory, :bigint

    Syndication::Product.connection.change_column :syndication_products, :wishlist_id, :bigint
  end
end
