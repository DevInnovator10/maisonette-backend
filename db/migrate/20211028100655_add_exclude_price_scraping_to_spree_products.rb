class AddExcludePriceScrapingToSpreeProducts < ActiveRecord::Migration[6.0]

  def change
    add_column :spree_products, :exclude_price_scraping, :boolean, default: false
  end
end
