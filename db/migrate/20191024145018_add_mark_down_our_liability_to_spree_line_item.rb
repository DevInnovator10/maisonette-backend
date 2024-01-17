class AddMarkDownOurLiabilityToSpreeLineItem < ActiveRecord::Migration[5.2]

    def change
    add_column :spree_line_items, :mark_down_our_liability, :decimal
  end
end
