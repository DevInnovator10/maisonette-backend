class AddMiraklCodeToSpreeRefundReasons < ActiveRecord::Migration[5.2]
    def change
    add_column :spree_refund_reasons, :mirakl_code, :integer
  end
end
