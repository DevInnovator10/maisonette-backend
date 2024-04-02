class AddCostPriceToSpreeSalePrices < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_sale_prices, :cost_price, :decimal, precision: 8, scale: 2
  end
end
