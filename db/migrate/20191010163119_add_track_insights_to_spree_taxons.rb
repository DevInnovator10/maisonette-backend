class AddTrackInsightsToSpreeTaxons < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_taxons, :track_insights, :boolean, default: false
  end
end
