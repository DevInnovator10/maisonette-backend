class AddCreatedByAndUpdatedByToSaleSkuConfigurations < ActiveRecord::Migration[6.0]
  def change
    add_reference :maisonette_sale_sku_configurations,
                  :created_by,
                  foreign_key: { to_table: Spree.user_class.table_name },
                  index: true
    add_reference :maisonette_sale_sku_configurations,
                  :updated_by,
                  foreign_key: { to_table: Spree.user_class.table_name },
                  index: true
  end
end
