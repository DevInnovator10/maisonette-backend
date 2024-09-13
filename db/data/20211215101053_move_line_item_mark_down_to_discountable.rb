class MoveLineItemMarkDownToDiscountable < ActiveRecord::Migration[6.0]
  def up
    Spree::LineItem.where.not(mark_down_id: nil)
                   .update_all("discountable_id = mark_down_id, discountable_type = 'Spree::MarkDown'")
  end

  def down
    Spree::LineItem.where.not(mark_down_id: nil)
                   .update_all("discountable_id = NULL, discountable_type = NULL")
  end
end
