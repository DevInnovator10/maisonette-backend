# This migration comes from solidus_sale_prices (originally 20181128102526)
class AddCalculatedPriceToSpreeSalePrices < SolidusSupport::Migration[5.2]
  def change

    add_column :spree_sale_prices, :calculated_price, :decimal, precision: 10, scale: 2
  end
end
