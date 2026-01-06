class AddMarketplaceSkuToSyndicationTable < ActiveRecord::Migration[5.2]
  def change
    Syndication::Product.connection.add_column :syndication_products, :marketplace_sku, :string

  end
end
