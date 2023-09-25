class AddMiraklCodeToSpreeReturnReasons < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_return_reasons, :mirakl_code, :integer
  end
end
