class AddMiraklOfferAndMarkDownToSpreeLineItems < ActiveRecord::Migration[5.2]
  def change
    add_reference :spree_line_items, :mirakl_offer
    add_reference :spree_line_items, :mark_down
  end
end
