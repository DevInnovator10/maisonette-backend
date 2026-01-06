class AddMiraklShippingMethodCodeToSpreeShippingMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :mirakl_shipping_method_code, :string
  end
end
