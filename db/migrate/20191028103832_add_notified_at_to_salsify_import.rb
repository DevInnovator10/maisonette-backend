class AddNotifiedAtToSalsifyImport < ActiveRecord::Migration[5.2]
  def change
    add_column :salsify_imports, :notified_at, :timestamp
  end
end
