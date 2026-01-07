class AddDocNumberToMiraklInvoices < ActiveRecord::Migration[5.2]
  def change
    add_column :mirakl_invoices, :doc_number, :integer
  end
end
