class AddAvailableUntilToVariantGroupAttributes < ActiveRecord::Migration[6.0]
  def change
    add_column :maisonette_variant_group_attributes, :available_until, :datetime
  end
end
