class AddAdjustmentAmountToMaisonetteShippingInvoice < ActiveRecord::Migration[5.2]
  def change
    add_column :maisonette_shipping_invoices, :adjustment_amount, :float
  end

end
