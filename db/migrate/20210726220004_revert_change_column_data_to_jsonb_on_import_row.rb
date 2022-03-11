class RevertChangeColumnDataToJsonbOnImportRow < ActiveRecord::Migration[6.0]
  def up
    # change_column :salsify_import_rows, :data, :text, using: 'data::jsonb::text', null: true, default: nil
  end

  def down
    # change_column :salsify_import_rows, :data, :jsonb, using: 'data::text::jsonb', null: false, default: {}
  end
end
