class DropSyndicationProducts < ActiveRecord::Migration[5.2]
  def change
    drop_table :syndication_products
  end
end
