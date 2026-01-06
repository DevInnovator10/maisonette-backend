class AddStatusToEasypostTrackers < ActiveRecord::Migration[5.2]
  def change
    add_column :easypost_trackers, :status, :string
  end

end
