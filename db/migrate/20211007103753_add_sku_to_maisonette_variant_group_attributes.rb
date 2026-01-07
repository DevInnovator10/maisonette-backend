class AddSkuToMaisonetteVariantGroupAttributes < ActiveRecord::Migration[6.0]
  def change
    add_column :maisonette_variant_group_attributes, :sku, :string
  end
end
