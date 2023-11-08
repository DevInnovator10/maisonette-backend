class ChangeSourceIdOnLogEntryToUuid < ActiveRecord::Migration[5.2]
  def up
    change_column :spree_log_entries, :source_id, :string
  end

  def down
    change_column :spree_log_entries, :source_id, :integer
  end
end
