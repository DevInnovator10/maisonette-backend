class AddOfferSettingsToSpreePrices < ActiveRecord::Migration[5.2]
  def up
    add_belongs_to :spree_prices, :offer_settings, index: true

    sql = <<~SQL
      UPDATE spree_prices
      SET offer_settings_id = os.id
      FROM spree_prices AS sp
      LEFT JOIN mirakl_offers AS mo ON sp.id = mo.spree_price_id
      LEFT JOIN spree_offer_settings AS os ON mo.sku = os.maisonette_sku
      WHERE spree_prices.id = sp.id
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
    remove_column :spree_prices, :offer_settings_id
  end
end
