class CreateShippingInvoices < ActiveRecord::Migration[5.2]
  def change

    create_table :shipping_invoices do |t|
      t.belongs_to :easypost_order, unique: true

      t.float :amount
      t.float :weight
      t.string :weight_unit
      t.string :order_number, index: true
      t.string :invoice_number
      t.string :billing_account
      t.string :tracking_code, index: true, unique: true
      t.string :carrier
      t.datetime  :transaction_date

    end
  end
end
