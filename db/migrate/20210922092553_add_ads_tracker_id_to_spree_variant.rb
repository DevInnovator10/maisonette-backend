class AddAdsTrackerIdToSpreeVariant < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_variants, :fixed_ref, :string
  end
end
