class AddOrderFeeToMiraklShops < ActiveRecord::Migration[5.2]
    def change
    add_column :mirakl_shops, :order_fee_parcel, :decimal
    add_column :mirakl_shops, :order_fee_freight, :decimal
  end
end
