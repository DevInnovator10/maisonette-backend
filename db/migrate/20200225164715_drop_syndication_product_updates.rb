class DropSyndicationProductUpdates < ActiveRecord::Migration[5.2]
  def change
    drop_table :syndication_product_updates

  end
end
