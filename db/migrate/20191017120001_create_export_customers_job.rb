# frozen_string_literal: true

class CreateExportCustomersJob < ActiveRecord::Migration[5.2]
    def change
    create_table :listrak_export_customers_jobs do |t|
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.attachment :customers

      t.timestamps
    end
  end
end
