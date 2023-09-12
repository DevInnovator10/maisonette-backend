class CreateMaisonetteSales < ActiveRecord::Migration[6.0]
  def change
    create_table :maisonette_sales do |t|
      t.string :name, null: false
      t.decimal :percent_off, null: false
      t.decimal :maisonette_liability, null: false
      t.datetime :start_date, null: false
      t.datetime :end_date
      t.boolean :final_sale
      t.boolean :permanent

      t.timestamps
    end
  end
end
