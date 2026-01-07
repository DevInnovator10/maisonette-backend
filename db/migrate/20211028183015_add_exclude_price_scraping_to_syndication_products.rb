class AddExcludePriceScrapingToSyndicationProducts < ActiveRecord::Migration[6.0]
  def change
    Syndication::Product.connection.add_column :syndication_products, :exclude_price_scraping, :boolean, default: false
  end
end
