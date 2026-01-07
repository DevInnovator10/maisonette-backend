class AddStaticSalePriceAndStaticCostPriceToSaleSkuConfigurations < ActiveRecord::Migration[6.0]
  def change
    add_column :maisonette_sale_sku_configurations, :static_sale_price, :decimal, precision: 10, scale: 2
    add_column :maisonette_sale_sku_configurations, :static_cost_price, :decimal, precision: 10, scale: 2
  end
end
