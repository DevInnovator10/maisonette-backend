class ChangeSpreeReimbursementPromotionsToSpreeReimbursementGiftCards < ActiveRecord::Migration[5.2]
  def self.up
    rename_table :spree_reimbursement_promotions, :spree_reimbursement_gift_cards
  end

  def self.down
    rename_table :spree_reimbursement_gift_cards , :spree_reimbursement_promotions
  end
end
