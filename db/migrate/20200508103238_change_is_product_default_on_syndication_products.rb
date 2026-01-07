class ChangeIsProductDefaultOnSyndicationProducts < ActiveRecord::Migration[5.2]
  def up
    Syndication::Product.connection.change_column :syndication_products, :is_product, :boolean, default: false
  end

  def down
    Syndication::Product.connection.change_column :syndication_products, :is_product, :boolean, default: nil
  end
end
