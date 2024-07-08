class AddOrderIdToMaisonetteGiftwrap < ActiveRecord::Migration[5.2]
  def change
    add_reference :maisonette_giftwraps, :order, foreign_key: { to_table: :spree_orders }
  end
end
