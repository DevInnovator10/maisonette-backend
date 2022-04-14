class CreateSalsifyMiraklOfferExportJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :salsify_mirakl_offer_export_jobs do |t|
      t.integer :status, default: 10
      t.datetime :import_executed_at
      t.datetime :import_finished_at
      t.text :error_message
      t.text :synchro_ids
      t.timestamps null: false
    end
  end
end
