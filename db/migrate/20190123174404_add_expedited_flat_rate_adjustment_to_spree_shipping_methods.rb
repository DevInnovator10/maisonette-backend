class AddExpeditedFlatRateAdjustmentToSpreeShippingMethods < ActiveRecord::Migration[5.2]
    def change
    change_table :spree_shipping_methods, bulk: true do |t|

      t.string :flat_rate_class, default: nil
      t.decimal :expedited_flat_rate_adjustment, scale: 2, precision: 8, default: 0.0
    end
  end
end
