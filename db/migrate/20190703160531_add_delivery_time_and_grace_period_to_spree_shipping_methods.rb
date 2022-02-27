class AddDeliveryTimeAndGracePeriodToSpreeShippingMethods < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipping_methods, :delivery_time, :integer
    add_column :spree_shipping_methods, :grace_period, :integer
  end
end
