# frozen_string_literal: true

class AddColumnsToShippingInvoices < ActiveRecord::Migration[5.2]
    def change
    change_table(:shipping_invoices, bulk: true) do |t|
      t.column :internal_reference, :string
      t.column :sender_name, :string
      t.timestamps
    end
  end
end
