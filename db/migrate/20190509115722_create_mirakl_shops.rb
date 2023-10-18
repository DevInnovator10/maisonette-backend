class CreateMiraklShops < ActiveRecord::Migration[5.2]
  def change
    create_table :mirakl_shops do |t|
      t.integer :shop_id, null: false, index: true
      t.integer :shop_status
      t.integer :compliance_violation_fee_type
      t.integer :lead_time_ship_leniency, default: 0
      t.float :compliance_violation_fee, default: 0.0
      t.float :transaction_fee_percentage, default: 0.0
      t.float :gift_wrap_fee, default: 0.0
      t.float :dropship_surcharge, default: 0.0
      t.string :name
      t.string :tax_id_number
      t.string :easypost_api_key
      t.string :working_hr_start_time, default: '800'
      t.string :fulfil_by_eod_cutoff_time, default: '1400'
      t.boolean :generate_returns_label, default: true
      t.boolean :manage_own_shipping, default: false
      t.boolean :cost_price, default: false
      t.boolean :tx_fee_24hr_ship_waiver, default: false
      t.boolean :send_shipping_cost, default: false
      t.boolean :premium, default: false

      t.timestamps
    end
  end
end
