# frozen_string_literal: true

class AddBulkDocumentFieldsToMiraklModels < ActiveRecord::Migration[5.2]
  def change
    add_column :mirakl_orders, :acceptance_decision_date, :datetime
    add_column :mirakl_orders, :bulk_document_sent, :boolean, default: false
    add_column :mirakl_shops, :generate_bulk_document, :boolean, default: false
    add_column :mirakl_shops, :email, :string
  end
end
