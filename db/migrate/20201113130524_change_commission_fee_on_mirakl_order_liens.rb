class ChangeCommissionFeeOnMiraklOrderLiens < ActiveRecord::Migration[5.2]
  def up

    change_column :mirakl_order_lines, :commission_fee, :decimal, precision: 8, scale: 2
  end

  def down
    change_column :mirakl_order_lines, :commission_fee, :integer
  end
end
