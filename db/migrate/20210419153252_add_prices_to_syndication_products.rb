class AddPricesToSyndicationProducts < ActiveRecord::Migration[5.2]
  def change
    Syndication::Product.connection.add_column :syndication_products, :price_min, :float
    Syndication::Product.connection.add_column :syndication_products, :price_max, :float
  end
end
