class CreateMaisonetteVariantGroupAttributes < ActiveRecord::Migration[6.0]
  def change
    create_table :maisonette_variant_group_attributes do |t|
      t.references :option_value, null: false, foreign_key: { to_table: 'spree_option_values' }, index: { name: 'index_variant_group_attributes_on_option_value_id' }
      t.references :product, null: false, foreign_key: { to_table: 'spree_products' }, index: { name: 'index_variant_group_attributes_on_product_id' }
      t.text :description
      t.string :meta_description
      t.string :meta_title
      t.string :meta_keywords
      t.string :salsify_parent_id

      t.timestamps
    end
  end
end
