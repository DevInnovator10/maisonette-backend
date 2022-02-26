class CreateMiraklOrderLineReimbursements < ActiveRecord::Migration[5.2]
  def change
    create_table :mirakl_order_line_reimbursements do |t|
      t.decimal :amount, precision: 8, scale: 2
      t.decimal :tax, precision: 8, scale: 2
      t.decimal :commission_amount, precision: 8, scale: 2
      t.decimal :commission_tax, precision: 8, scale: 2
      t.decimal :shipping_amount, precision: 8, scale: 2
      t.decimal :shipping_tax, precision: 8, scale: 2
      t.decimal :total, precision: 8, scale: 2
      t.integer :quantity
      t.integer :refund_reason_id
      t.integer :order_line_id
      t.string :state
      t.integer :mirakl_type
      t.integer :mirakl_reimbursement_id

      t.timestamps null: false
    end

    add_index :mirakl_order_line_reimbursements, %i[mirakl_reimbursement_id mirakl_type],
              name: 'index_mirakl_order_line_reimbs_on_reimb_id_and_mirakl_type'
  end
end
