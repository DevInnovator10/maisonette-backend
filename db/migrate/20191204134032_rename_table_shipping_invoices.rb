class RenameTableShippingInvoices < ActiveRecord::Migration[5.2]
  def change
    rename_table :shipping_invoices, :maisonette_shipping_invoices

  end
end
