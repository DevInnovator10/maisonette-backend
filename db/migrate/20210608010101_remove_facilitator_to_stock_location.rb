class RemoveFacilitatorToStockLocation < ActiveRecord::Migration[5.2]
  def change
    remove_column :spree_stock_locations, :facilitator, :boolean
  end

end
