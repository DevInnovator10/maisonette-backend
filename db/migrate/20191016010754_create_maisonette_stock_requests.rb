class CreateMaisonetteStockRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :maisonette_stock_requests do |t|
      t.string :email
      t.string :state
      t.belongs_to :variant
      t.datetime :sent_at

      t.timestamps
    end
  end
end
