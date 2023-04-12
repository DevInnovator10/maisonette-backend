class AddCostPricesToSyndicationProduct < ActiveRecord::Migration[6.0]
  def change
    Syndication::Product.connection.add_column :syndication_products, :cost_price, :float
  end
end
