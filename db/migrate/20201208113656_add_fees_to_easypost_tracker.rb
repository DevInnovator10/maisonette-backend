class AddFeesToEasypostTracker < ActiveRecord::Migration[5.2]
  def change

    add_column :easypost_trackers, :fees, :text
  end
end
