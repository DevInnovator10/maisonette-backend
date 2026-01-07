class AddBelongsToPromotionCodeToSpreeReimbursementGiftCard < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :spree_reimbursement_gift_cards, :spree_promotion_code, index: false
  end

end
