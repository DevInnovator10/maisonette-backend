class SafeChangeColumnDataToJsonbOnImportRow < ActiveRecord::Migration[6.0]
  def change
    # rename_column :salsify_import_rows, :data, :legacy_data

    # add_column :salsify_import_rows, :data, :jsonb, null: false, default: {}
  end
end
