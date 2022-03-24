class RemoveNullConstraintOnLineItemMonogramCustomization < ActiveRecord::Migration[5.2]
  def change
    change_column_null :spree_line_item_monograms, :customization, true
  end
end
