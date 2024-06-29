class ChangeColumnsToFloatOnSyndicationProducts < ActiveRecord::Migration[5.2]
  def up
    Syndication::Product.connection.change_column :syndication_products, :maisonette_retail, :float
    Syndication::Product.connection.change_column :syndication_products, :maisonette_sale, :float
  end

  def down
    Syndication::Product.connection.change_column :syndication_products, :maisonette_retail, :decimal
    Syndication::Product.connection.change_column :syndication_products, :maisonette_sale, :decimal
  end
end
